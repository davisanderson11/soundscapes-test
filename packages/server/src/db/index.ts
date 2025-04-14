import config from "~/../mikro-orm.config"
import { RequestContext } from "@mikro-orm/core"
import { MikroORM } from "@mikro-orm/postgresql"
import type { FastifyInstance } from "fastify"

export const orm = MikroORM.initSync(config)

export const register = (server: FastifyInstance) => {
    server.addHook("onRequest", (_req, _res, done) => RequestContext.create(orm.em, done))
    server.addHook("onClose", async () => await orm.close())
}
