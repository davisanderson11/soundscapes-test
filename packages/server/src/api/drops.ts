import z from "zod"
import CheapRuler from "cheap-ruler"
import { authedProcedure, router } from "~/trpc"
import { orm } from "~/db"
import { Drop, Quad } from "~/db/entities"
import { TRPCError } from "@trpc/server"
import { SpotifyApi } from "@spotify/web-api-ts-sdk"
import { cache } from "~/cache"

const SCAN_R_KM = 1
const DROP_COOLDOWN_SEC = 2 //2 * 60 * 60

export const spotifyClient = SpotifyApi.withClientCredentials(
    process.env.SPOTIFY_CLIENT_ID!,
    process.env.SPOTIFY_CLIENT_SECRET!
)

export const dropsRouter = router({
    scan: authedProcedure
        .input(z.tuple([z.number(), z.number()]))
        .query(async ({ input: center }) => {
            const ruler = new CheapRuler(center[1], "kilometers")
            const containingQuads = getContainingQuadsForCircle(center, ruler)
            const existingQuads: Quad[] = []
            const allDrops: Drop[] = []
            for (const [lngMinutes, latMinutes] of containingQuads) {
                const quad = new Quad(latMinutes, lngMinutes)
                let quadDrops: Drop[] = []

                const existing = await orm.em.findOne(Quad, quad)
                if (existing === null) {
                    quadDrops = generateDropsForQuad(quad)
                    orm.em.persist(quad)
                    orm.em.persist(quadDrops)
                } else {
                    existingQuads.push(existing)
                }

                allDrops.push(...quadDrops)
            }

            // TODO: Optimize existingQuads into 1 query
            allDrops.push(...(await orm.em.find(Drop, { quad: { $in: existingQuads } })))

            await orm.em.flush()
            return allDrops
                .filter(drop => ruler.distance(drop.point, center) <= SCAN_R_KM)
                .map(({ quad: _, ...rest }) => ({ ...rest }))
        }),

    open: authedProcedure.input(z.number()).mutation(async ({ ctx: { userID }, input: dropID }) => {
        const drop = await orm.em.findOne(Drop, dropID)
        if (!drop) throw new TRPCError({ code: "NOT_FOUND" })

        const userDropKey = `user.drop:${userID}.${dropID}`
        if (cache.has(userDropKey)) throw new TRPCError({ code: "FORBIDDEN" })

        const AB_0 = "a".charCodeAt(0)
        const AB_SZ = "z".charCodeAt(0) - AB_0
        const letter = String.fromCharCode(AB_0 + Math.floor(Math.random() * AB_SZ))

        // TODO: user favorites?
        // TODO: use user's spotify client
        const offset = Math.floor(Math.random() * 500)
        const { tracks } = await spotifyClient.search(letter, ["track"], undefined, 1, offset)
        const track = tracks.items[0]
        const album = track.album ? await spotifyClient.albums.get(track.album.id) : null
        const artist = track.artists?.[0]?.name?? ""
        const value = Math.round(Math.random() * 100); // TODO: Value same for every identical song
        const testQuality = Math.round(Math.random() * 50) // TODO: Rarity "curve"

        cache.set(userDropKey, null, DROP_COOLDOWN_SEC)
        return { track, album, value, testQuality, artist }
    })
})

const getContainingQuadsForCircle = (center: Point, ruler: CheapRuler) => {
    const neMinutes = ruler.offset(center, SCAN_R_KM, SCAN_R_KM).map(deg => Math.floor(deg * 60))
    const swMinutes = ruler.offset(center, -SCAN_R_KM, -SCAN_R_KM).map(deg => Math.floor(deg * 60))

    const quads: QuadPoint[] = []
    for (let latMinutes = swMinutes[1]; latMinutes <= neMinutes[1]; latMinutes++)
        for (let lngMinutes = swMinutes[0]; lngMinutes <= neMinutes[0]; lngMinutes++)
            quads.push([lngMinutes, latMinutes])

    return quads
}

const generateDropsForQuad = (quad: Quad) => {
    const drops: Drop[] = []
    const randCoord = (minute: number) => parseFloat(((minute + Math.random()) / 60).toFixed(4))

    for (let i = 0; i < 20; i++)
        drops.push(
            new Drop(
                randCoord(quad.latitudeMinutes),
                randCoord(quad.longitudeMinutes),
                Math.random() < 0.1,
                quad
            )
        )

    return drops
}

/** Longitude, latitude. */
type Point = [number, number]

/** Long, lat, in minutes. */
type QuadPoint = [number, number]
