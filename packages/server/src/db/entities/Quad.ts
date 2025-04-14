import { Entity, PrimaryKey, Property } from "@mikro-orm/core"

@Entity()
export class Quad {
    @PrimaryKey()
    id: number

    @Property()
    latitudeMinutes!: number

    @Property()
    longitudeMinutes!: number

    constructor(latMin: number, lngMin: number) {
        this.latitudeMinutes = latMin
        this.longitudeMinutes = lngMin
        this.id = this.hash
    }

    private get hash() {
        const latNorm = this.latitudeMinutes + 90 * 60
        const lngNorm = this.longitudeMinutes + 180 * 60
        const maxLngNorm = 180 * 60 * 2 + 1
        return latNorm * maxLngNorm + lngNorm
    }
}
