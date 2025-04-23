import "dotenv/config"
import fastify from "fastify"
import { register as registerDB } from "./db"
import { register as registerAPI } from "./api"
import { Drop } from "~/db/entities/Drop";
import { em } from "~/db"; 

const server = fastify({ maxParamLength: 5000 })
registerDB(server)
registerAPI(server)
em.find(Drop, {}).then(console.log).catch(console.error);

server.listen({ host: "0.0.0.0", port: 3000 }, (err, addr) => {
    if (err) {
        server.log.error(err)
        process.exit(1)
    } else {
        console.log(`Server listening on ${addr}.`)
    }
})
