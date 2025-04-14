import { Entity, PrimaryKey, Property } from "@mikro-orm/core"

@Entity()
export class User {
    @PrimaryKey()
    id!: number

    @Property()
    spotifyID!: string

    @Property()
    avatar!: string

    constructor(spotifyID: string, avatar: string) {
        this.spotifyID = spotifyID
        this.avatar = avatar
    }
}
