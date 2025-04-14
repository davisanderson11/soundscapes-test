import { Text as NativeText, type TextProps } from "react-native"

export const Text = ({ ...props }: TextProps) => {
    return (
        <NativeText
            style={{ color: "#ECEDEE" }}
            // className={cn("text-[#11181C] dark:text-[#ECEDEE]", textClass, className)}
            {...props}
        />
    )
}
