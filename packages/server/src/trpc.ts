import { jwtVerify } from "jose"
import { initTRPC, TRPCError } from "@trpc/server"
import type { Context } from "./context"

const t = initTRPC.context<Context>().create()

export const router = t.router
export const publicProcedure = t.procedure
// TODO: fetch/cache user in this middleware to make sure they exist etc
export const authedProcedure = t.procedure.use(
    t.middleware(async ({ ctx, next }) => {
        const jwt = ctx.req.headers.authorization?.split(" ")[1]
        if (!jwt) throw new TRPCError({ code: "UNAUTHORIZED" })

        const { payload } = await jwtVerify(jwt, jwtSecret).catch(() => {
            throw new TRPCError({ code: "UNAUTHORIZED" })
        })

        return next({ ctx: { userID: parseInt(payload.sub!) } })
    })
)

export const jwtSecret = new TextEncoder().encode(process.env.JWT_SECRET)
