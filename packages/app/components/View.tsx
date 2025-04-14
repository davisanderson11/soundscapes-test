import { View as NativeView, type ViewProps } from "react-native"

export const View = ({ ...props }: ViewProps) => {
    return (
        <NativeView
            style={{ backgroundColor: "#151718" }}
            // className={cn("bg-white dark:bg-[#151718]", className)}
            {...props}
        />
    )
}
