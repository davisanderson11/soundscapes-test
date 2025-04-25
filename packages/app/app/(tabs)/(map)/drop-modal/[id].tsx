import { useLocalSearchParams } from "expo-router"
import { Image, Button, ToastAndroid } from "react-native"
import { Text, View } from "~/components/"
import { trpc } from "~/utils/trpc"

export default function DropModal() {
    const params = useLocalSearchParams()
    const dropID = parseInt(params.id as string)
    const openMutation = trpc.drops.open.useMutation({
        onError: () => ToastAndroid.show("Cooldown", ToastAndroid.SHORT)
    })

    return (
        <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
            <Text>ok {dropID}</Text>
            <Button title="Open" onPress={() => openMutation.mutate(dropID)} />
            {openMutation.isSuccess && (
                <>
                    <Image
                        style={{ width: 200, height: 200 }}
                        src={openMutation.data.album.images[0].url}
                    />
                    <Text style = {{color: 'red'}}>{openMutation.data.track.name}</Text>
                    <Text style = {{color: 'red'}}>Test Value: {openMutation.data.value}</Text>
                    <Text style = {{color: 'red'}}>Test Quality: {openMutation.data.testQuality}</Text>
                </>
            )}
        </View>
    )
}
