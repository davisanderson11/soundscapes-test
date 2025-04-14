import type { AppRouter } from "server/src/api"
import { createTRPCReact } from "@trpc/react-query"
import { httpBatchLink } from "@trpc/client"
import { QueryClient } from "@tanstack/react-query"
import Constants from "expo-constants"

// TODO: Production URL
const hostIP = Constants.expoConfig?.hostUri?.split(":")[0]
if (hostIP == null) throw new Error("Expo dev server IP not found.")
const apiURL = `http://${hostIP}:3000/trpc`

let token: string | null = null
export const setToken = (jwt: string | null) => (token = jwt)

export const queryClient = new QueryClient()
export const trpc = createTRPCReact<AppRouter>()
export const trpcClient = trpc.createClient({
    links: [
        httpBatchLink({ url: apiURL, headers: () => ({ Authorization: `Bearer ${token ?? ""}` }) })
    ]
})
