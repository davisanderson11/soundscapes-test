import type { AppRouter } from "server/src/api";
import { createTRPCReact } from "@trpc/react-query";
import { httpBatchLink } from "@trpc/client";
import { QueryClient } from "@tanstack/react-query";
import Constants from "expo-constants";
import { Platform } from "react-native";

/* ------------------------------------------------------------------
 * Resolve the host the mobile app should contact on port 3000
 * ------------------------------------------------------------------
 * Order of precedence:
 *   1.  EXPO_PUBLIC_API_HOST       – set in .env when you need a tunnel
 *   2.  Expo dev‑server hostUri    – works on physical devices over Wi‑Fi
 *   3.  Fallback:
 *         • Android emulator → 10.0.2.2   (maps to host machine)
 *         • iOS simulator   → localhost
 * ----------------------------------------------------------------- */

const fallbackHost = Platform.OS === "android" ? "10.0.2.2" : "localhost";

const host =
  process.env.EXPO_PUBLIC_API_HOST ??                       // 1
  Constants.expoConfig?.hostUri?.split(":")[0] ??           // 2
  fallbackHost;                                             // 3

export const apiURL = `http://${host}/trpc`;
console.log("🔗 trpc apiURL =>", apiURL);

/* ------------------------------------------------------------------
 * Auth token storage
 * ----------------------------------------------------------------- */

let token: string | null = null;
export const setToken = (jwt: string | null) => (token = jwt);

/* ------------------------------------------------------------------
 * tRPC + React Query client
 * ----------------------------------------------------------------- */

export const queryClient = new QueryClient();

export const trpc = createTRPCReact<AppRouter>();
export const trpcClient = trpc.createClient({
  links: [
    httpBatchLink({
      url: apiURL,
      headers: () => ({
        Authorization: `Bearer ${token ?? ""}`,
      }),
    }),
  ],
});
