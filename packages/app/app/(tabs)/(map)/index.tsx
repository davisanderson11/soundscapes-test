import Mapbox, { MapView, LocationPuck, PointAnnotation, Camera, StyleImport } from "@rnmapbox/maps"
import { useEffect, useRef } from "react"
import { trpc } from "~/utils/trpc"
import { Text, View } from "~/components"
import { Image, Pressable } from "react-native"
import { useSession } from "~/components/AuthContext"
import { useLocation } from "~/hooks/useLocation"
import { useRouter } from "expo-router"
import { useFauxMarkers } from "~/hooks/useFauxMarkers"

void Mapbox.setAccessToken(process.env.EXPO_PUBLIC_MAPBOX_TOKEN!)

const presetMap: Record<number, string> = {
    5:  "dawn",
    8:  "day",
    18: "dusk",
    20: "night",    
  }

const hour = new Date().getHours()
const time = Object
  .keys(presetMap)
  .map(Number)
  .sort((a,b) => a - b)
  .reduce(
    (acc,from) => hour >= from ? presetMap[from] : acc,
    "night"
  )

export default function MapScreen() {
    useEffect(() => Mapbox.setTelemetryEnabled(false), [])

    const location = useLocation()
    const session = useSession()

    const fallbackCoords = undefined
    const coords = location?.coords.longitude
        ? ([location.coords.longitude, location.coords.latitude] as [number, number])
        : fallbackCoords

    const profile = trpc.users.me.useQuery()
    const drops = trpc.drops.scan.useQuery(coords!, { enabled: coords != null })
    if (drops.data) {
        console.log("drops loaded")
    }

    const router = useRouter()
    const onMarkerPress = (id: number) => router.push(`/drop-modal/${id}`)
    const [onSelected, onDeselected] = useFauxMarkers(onMarkerPress)
    if (coords) {
        console.log("coords")
    }

    // camera ref for imperative movements
    const cameraRef = useRef<Camera>(null)
    useEffect(() => {
        if (!coords) return
        cameraRef.current?.setCamera({
            centerCoordinate: coords,
            zoomLevel: 14,
            animationDuration: 0,
        })
    }, [coords])

    return (
        <View style={{ flex: 1 }}>
            <View style={{ position: "absolute", top: 32, right: 12, zIndex: 1 }}>
                {profile.data && (
                    <Pressable onPress={session.signOut}>
                        <Image
                            style={{ width: 50, height: 50, borderRadius: 100, borderColor: "white" }}
                            src={profile.data.avatar}
                        />
                    </Pressable>
                )}
            </View>

            <MapView
                attributionPosition={{ bottom: 8, left: 8 }}
                logoEnabled={false}
                scaleBarEnabled={false}
                style={{ flex: 1 }}
                projection="globe"
                styleURL="mapbox://styles/mapbox/standard"
            >
                {drops.isSuccess &&
                    drops.data.map(drop => (
                        <PointAnnotation
                            key={drop.id.toString()}
                            id={drop.id.toString()}
                            onSelected={() => onSelected(drop.id)}
                            onDeselected={() => onDeselected(drop.id)}
                            coordinate={[drop.longitude, drop.latitude]}
                        >
                            <View
                                style={{
                                    backgroundColor: drop.special ? "red" : "blue",
                                    width: 24,
                                    height: 24,
                                }}
                            >
                                <Text>{drop.id}</Text>
                            </View>
                        </PointAnnotation>
                    ))}

                <StyleImport id="basemap" existing config={{ lightPreset: time }} />
                <Camera
                    ref={cameraRef}
                    zoomLevel={14}
                    animationDuration={0}
                    // TODO: Setting for 3D (pitch={45})
                />
                <LocationPuck
                    puckBearingEnabled
                    puckBearing="heading"
                    pulsing={{ radius: 15, isEnabled: true }}
                />
            </MapView>
        </View>
    )
}
