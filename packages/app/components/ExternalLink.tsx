import { Link, type Href } from "expo-router"
import { openBrowserAsync } from "expo-web-browser"
import type { ComponentProps } from "react"

export function ExternalLink({ href, ...rest }: ExternalLinkProps) {
    return (
        <Link
            target="_blank"
            {...rest}
            href={href as Href<string>}
            onPress={async event => {
                event.preventDefault()
                await openBrowserAsync(href)
            }}
        />
    )
}

export type ExternalLinkProps = Omit<ComponentProps<typeof Link>, "href"> & { href: string }
