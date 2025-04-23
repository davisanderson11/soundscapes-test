import "dotenv/config";                     // 1) load env FIRST
import config from "~/../mikro-orm.config"
import { RequestContext } from "@mikro-orm/core"
import { MikroORM } from "@mikro-orm/postgresql"
import { PostgreSqlDriver } from "@mikro-orm/postgresql"
import type { FastifyInstance } from "fastify"

export const orm = MikroORM.initSync<PostgreSqlDriver>(config)
export const em  = orm.em.fork()

export const register = (server: FastifyInstance) => {
    server.addHook("onRequest", (_req, _res, done) => RequestContext.create(orm.em, done))
    server.addHook("onClose", async () => await orm.close())
}
