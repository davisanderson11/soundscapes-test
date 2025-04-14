import { useContext, createContext, type PropsWithChildren } from "react"
import { useStorageState } from "~/hooks/useStorageState"
import { setToken as setTRPCToken } from "~/utils/trpc"
import { useEffect } from "react"

const AuthContext = createContext<{
    signIn: (token: string) => void
    signOut: () => void
    token?: string | null
    isLoading: boolean
    loaded: boolean
} | null>(null)

export function useSession() {
    const value = useContext(AuthContext)
    if (!value && !__DEV__) throw new Error("useSession must be wrapped in a <SessionProvider />")
    return value!
}

export function SessionProvider({ children }: PropsWithChildren) {
    const [[isLoading, token], setToken] = useStorageState("token")
    useEffect(() => void setTRPCToken(token), [token])

    return (
        <AuthContext.Provider
            value={{
                signIn: (token: string) => setToken(token),
                signOut: () => setToken(null),
                token,
                isLoading,
                loaded: !isLoading
            }}
        >
            {children}
        </AuthContext.Provider>
    )
}
