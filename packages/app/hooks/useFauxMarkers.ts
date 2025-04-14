import { useRef } from "react"

// MarkerViews are jiggly (lag behind on pan), so we use PointAnnotations instead,
// which don't have a simple onPress prop...
export function useFauxMarkers(onPress: (id: number) => void) {
    const selected = useRef<number | null>(null)

    const onSelected = (id: number) => {
        onPress(id)
        console.log("sel", id)
        selected.current = id
    }

    const onDeselected = (id: number) => {
        console.log("des", id)

        if (selected.current === null) return console.error("Faux marker ref out of sync") // ?
        selected.current = null

        setTimeout(() => {
            if (selected.current === null) onPress(id)
        }, 10)
    }

    return [onSelected, onDeselected]
}
