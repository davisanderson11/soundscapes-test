import { trpc, trpcClient, queryClient } from "~/utils/trpc"
import { QueryClientProvider } from "@tanstack/react-query"
import { DarkTheme, DefaultTheme, ThemeProvider } from "@react-navigation/native"
import { SessionProvider } from "~/components/AuthContext"
import { useColorScheme } from "react-native"
import { SplashScreen, Stack } from "expo-router"

void SplashScreen.preventAutoHideAsync()

export default function RootLayout() {
    const colorScheme = useColorScheme()

    return (
        <trpc.Provider client={trpcClient} queryClient={queryClient}>
            <QueryClientProvider client={queryClient}>
                <SessionProvider>
                    <ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
                        <Stack screenOptions={{ headerShown: false }}>
                            <Stack.Screen name="(tabs)" />
                            <Stack.Screen name="sign-in" />
                            <Stack.Screen name="+not-found" />
                        </Stack>
                    </ThemeProvider>
                </SessionProvider>
            </QueryClientProvider>
        </trpc.Provider>
    )
}
