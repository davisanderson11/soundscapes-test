import { router } from "~/trpc"
import type { FastifyInstance } from "fastify"
import { fastifyTRPCPlugin, type FastifyTRPCPluginOptions } from "@trpc/server/adapters/fastify"
import { createContext } from "~/context"
import { authRouter } from "./auth"
import { dropsRouter } from "./drops"
import { usersRouter } from "./users"

export const appRouter = router({
    auth: authRouter,
    drops: dropsRouter,
    users: usersRouter
})

export const register = (server: FastifyInstance) => {
    server.register(fastifyTRPCPlugin, {
        prefix: "/trpc",
        trpcOptions: {
            router: appRouter,
            createContext,
            onError: ({ path, error }) =>
                console.error(`Error in tRPC handler on path '${path ?? "(?)"}':`, error)
        }
    } satisfies FastifyTRPCPluginOptions<AppRouter>)
}

export type AppRouter = typeof appRouter
