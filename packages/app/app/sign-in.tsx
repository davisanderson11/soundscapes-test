import { View } from "~/components"
import { Button } from "react-native"
import { useEffect } from "react"
import { useAuthRequest, type AuthRequestConfig, type DiscoveryDocument } from "expo-auth-session"
import { trpc } from "~/utils/trpc"
import Constants from "expo-constants"
import { useSession } from "~/components/AuthContext"
import { Redirect } from "expo-router"

export default function SignIn() {
    const [authRequest, authResponse, promptAuth] = useAuthRequest(oauth.config, oauth.discovery)
    const spotifyAuthMutation = trpc.auth.withSpotify.useMutation()
    const session = useSession()

    useEffect(() => {
        // TODO: handle other types
        if (authResponse?.type === "success")
            spotifyAuthMutation.mutate(
                { code: authResponse.params.code },
                // TODO: handle onError
                { onSuccess: ({ jwt }) => session.signIn(jwt) }
            )
    }, [authResponse?.type])

    if (session.token) return <Redirect href="/(tabs)/" />

    return (
        <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
            <Button
                disabled={!authRequest}
                onPress={() => promptAuth()}
                color="#1ED760"
                title="Log in with Spotify"
            />
        </View>
    )
}

const oauth = {
    config: {
        clientId: process.env.EXPO_PUBLIC_SPOTIFY_CLIENT_ID!,
        scopes: ["user-read-email", "playlist-modify-public"],
        redirectUri: `${Constants.expoConfig!.scheme as string}://`,
        usePKCE: false // too many headaches; just obtain tokens server-side
    } satisfies AuthRequestConfig,
    discovery: {
        authorizationEndpoint: "https://accounts.spotify.com/authorize",
        tokenEndpoint: "https://accounts.spotify.com/api/token"
    } satisfies DiscoveryDocument
}
