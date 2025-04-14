import { Entity, FloatType, ManyToOne, PrimaryKey, Property } from "@mikro-orm/core"
import type { Quad } from "./Quad"

@Entity()
export class Drop {
    @PrimaryKey()
    id!: number

    @Property({ type: FloatType })
    latitude!: number

    @Property({ type: FloatType })
    longitude!: number

    @Property()
    special!: boolean

    @ManyToOne()
    quad!: Quad

    constructor(latitude: number, longitude: number, special: boolean, quad: Quad) {
        this.latitude = latitude
        this.longitude = longitude
        this.special = special
        this.quad = quad
    }

    get point() {
        return [this.longitude, this.latitude] as [number, number]
    }
}
