import z from "zod"
import { router, publicProcedure } from "~/trpc"
import { OAuth2 } from "oauth"
import { SpotifyApi } from "@spotify/web-api-ts-sdk"
import { User } from "~/db/entities/User"
import { orm } from "~/db/index"
import { SignJWT } from "jose"
import { jwtSecret } from "~/trpc"

export const authRouter = router({
    withSpotify: publicProcedure
        .input(z.object({ code: z.string() }))
        .mutation(async ({ input: { code } }) => {
            const tokens = await getSpotifyTokens(code)
            const spotify = SpotifyApi.withAccessToken(process.env.SPOTIFY_CLIENT_ID!, tokens)

            const profile = await spotify.currentUser.profile()
            const defaultAvatar = "https://scdn.co/image/ab67616d00001e02d65f098bb706fd41191521ba"
            const user = await orm.em.upsert(new User(profile.id, profile.images[0]?.url))

            const jwt = await new SignJWT()
                .setIssuedAt()
                .setSubject(user.id.toString())
                .setExpirationTime("1 day")
                .setProtectedHeader({ alg: "HS256" })
                .sign(jwtSecret)

            return { jwt }
        })
})

// we can't use Spotify SDK for this because it's opinionated (forces PKCE on us)
const getSpotifyTokens = (code: string) =>
    new Promise<SpotifyTokens>((res, rej) =>
        spotifyOAuth.getOAuthAccessToken(
            code,
            { grant_type: "authorization_code", redirect_uri: "soundscapes://" },
            // TODO: get better OAuth typings... or a better OAuth library altogether.
            (err, _, ref, toks) =>
                // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
                err ? rej(err) : res({ ...(toks as SpotifyTokens), refresh_token: ref! })
        )
    )

console.log("id-len", process.env.SPOTIFY_CLIENT_ID!.length);
console.log("secret-len", process.env.SPOTIFY_CLIENT_SECRET!.length);
console.log("id raw", JSON.stringify(process.env.SPOTIFY_CLIENT_ID));
console.log("secret raw", JSON.stringify(process.env.SPOTIFY_CLIENT_SECRET));


const spotifyOAuth = new OAuth2(
    process.env.SPOTIFY_CLIENT_ID!,
    process.env.SPOTIFY_CLIENT_SECRET!,
    "https://accounts.spotify.com",
    "/authorize",
    "/api/token"
)

interface SpotifyTokens {
    access_token: string
    token_type: "Bearer"
    scope: string[]
    expires_in: number
    refresh_token: string
}
