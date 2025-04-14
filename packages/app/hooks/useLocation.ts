import { useState, useEffect } from "react"
import * as Location from "expo-location"

export function useLocation() {
    const [location, setLocation] = useState<Location.LocationObject | null>(null)

    useEffect(() => {
        let sub: Location.LocationSubscription | undefined
        void (async () => {
            await Location.requestForegroundPermissionsAsync()
            // TODO: handle non-granted status
            await Location.getLastKnownPositionAsync({ maxAge: 1000 * 60 * 5 }).then(setLocation)
            sub = await Location.watchPositionAsync({}, setLocation)
        })()
        return () => sub?.remove()
    }, [])

    if (location?.mocked && !__DEV__) return null
    else return location
}
