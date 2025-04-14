import "dotenv/config"
import fastify from "fastify"
import { register as registerDB } from "./db"
import { register as registerAPI } from "./api"

const server = fastify({ maxParamLength: 5000 })
registerDB(server)
registerAPI(server)

server.listen({ host: "0.0.0.0", port: 3000 }, (err, addr) => {
    if (err) {
        server.log.error(err)
        process.exit(1)
    } else {
        console.log(`Server listening on ${addr}.`)
    }
})
