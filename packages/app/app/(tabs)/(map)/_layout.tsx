import { Stack } from "expo-router"

export default function MapLayout() {
    return (
        <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="drop-modal/[id]" options={{ presentation: "modal" }} />
        </Stack>
    )
}
