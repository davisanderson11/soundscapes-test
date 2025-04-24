import Mapbox, { MapView, LocationPuck, PointAnnotation, Camera, StyleImport } from "@rnmapbox/maps"
import { useEffect } from "react"
import { trpc } from "~/utils/trpc"
import { Text, View } from "~/components"
import { Image, Pressable } from "react-native"
import { useSession } from "~/components/AuthContext"
import { useLocation } from "~/hooks/useLocation"
import { useRouter } from "expo-router"
import { useFauxMarkers } from "~/hooks/useFauxMarkers"

void Mapbox.setAccessToken(process.env.EXPO_PUBLIC_MAPBOX_TOKEN!)

export default function MapScreen() {
    useEffect(() => Mapbox.setTelemetryEnabled(false), [])

    const location = useLocation()
    const session = useSession()

    const coords = location?.coords.longitude
        ? ([location.coords.longitude, location.coords.latitude] as [number, number])
        : null
    if (!coords) {
        console.log("no coords!")
    }
    const profile = trpc.users.me.useQuery()
    const drops = trpc.drops.scan.useQuery(coords!, { enabled: coords != null })
    console.log("drops.features", drops.data?.length ?? 0);

    const router = useRouter()
    const onMarkerPress = (id: number) => router.push(`/drop-modal/${id}`)
    const [onSelected, onDeselected] = useFauxMarkers(onMarkerPress)
    const fallbackCoords = [-98.5, 39.5] as [number, number];
    console.log("coords: ", coords)

    return (
        <View style={{ flex: 1 }}>
            <View style={{ position: "absolute", top: 32, right: 12, zIndex: 1 }}>
                {profile.data && (
                    <Pressable onPress={session.signOut}>
                        <Image
                            style={{ width: 50, height: 50, borderRadius: 100 }}
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
                                    height: 24
                                }}
                            >
                                <Text>{drop.id}</Text>
                            </View>
                        </PointAnnotation>
                    ))}
                <StyleImport id="basemap" existing config={{ lightPreset: "night" }} />
                <Camera
                    zoomLevel={14}
                    animationDuration={0}
                    centerCoordinate={coords ?? undefined}
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
