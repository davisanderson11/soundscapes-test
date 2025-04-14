import { PostgreSqlDriver, type Options } from "@mikro-orm/postgresql"
import { TsMorphMetadataProvider } from "@mikro-orm/reflection"
import { Migrator } from "@mikro-orm/migrations"
import { Drop, Quad, User } from "~/db/entities"

export default {
    driver: PostgreSqlDriver,
    metadataProvider: TsMorphMetadataProvider,
    extensions: [Migrator],
    migrations: { pathTs: "./src/db/migrations" },
    dbName: "soundscapes",
    entities: [Drop, Quad, User]
} satisfies Options
