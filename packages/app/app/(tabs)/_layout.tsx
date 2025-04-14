import { useEffect, type ComponentProps } from "react"
import type { IconProps } from "@expo/vector-icons/build/createIconSet"
import Ionicons from "@expo/vector-icons/Ionicons"
import { SplashScreen, Redirect, Tabs } from "expo-router"
import { useSession } from "~/components/AuthContext"

export default function TabLayout() {
    const session = useSession()

    useEffect(() => {
        if (session.loaded) void SplashScreen.hideAsync()
    }, [session.loaded])

    if (!session.token) return session.isLoading ? null : <Redirect href="/sign-in" />

    return (
        <Tabs
            screenOptions={{
                tabBarStyle: { height: 64 },
                tabBarLabelStyle: { marginBottom: 8 },
                headerShown: false
            }}
        >
            {[
                ["Map", "map", "(map)"],
                ["Trade", "repeat"],
                ["Collection", "albums"]
            ].map(([title, icon, href = `${title.toLowerCase()}/index`]) => (
                <Tabs.Screen
                    key={href}
                    name={href}
                    options={{
                        title,
                        tabBarIcon: ({ color, focused }) => (
                            <TabBarIcon
                                name={(icon + (focused ? "" : "-outline")) as IoniconName}
                                color={color}
                            />
                        )
                    }}
                />
            ))}
        </Tabs>
    )
}

type IoniconName = ComponentProps<typeof Ionicons>["name"]
function TabBarIcon({ style, ...rest }: IconProps<IoniconName>) {
    return <Ionicons size={28} style={[{ marginBottom: -3 }, style]} {...rest} />
}
