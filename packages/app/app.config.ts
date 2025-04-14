import type { ExpoConfig } from "expo/config"

module.exports = {
    name: "Soundscapes",
    slug: "soundscapes",
    version: "0.0.0",
    orientation: "portrait",
    icon: "./assets/images/icon.png",
    scheme: "soundscapes",
    userInterfaceStyle: "automatic",
    splash: {
        image: "./assets/images/splash.png",
        resizeMode: "contain",
        backgroundColor: "#ffffff"
    },
    ios: {
        supportsTablet: true
    },
    android: {
        adaptiveIcon: {
            foregroundImage: "./assets/images/adaptive-icon.png",
            backgroundColor: "#ffffff"
        },
        package: "com.soundscapes.app"
    },
    plugins: [
        "expo-router",
        "expo-secure-store",
        [
            "@rnmapbox/maps",
            {
                RNMapboxMapsDownloadToken: process.env.MAPBOX_DOWNLOADS_TOKEN,
                RNMapboxMapsVersion: "11.4.2"
            }
        ],
        ["expo-location", { locationWhenInUsePermission: "Show current location on map." }]
    ],
    extra: {
        eas: {
            projectId: "e99d2a25-09d7-485d-829e-ee450aaeabba"
        }
    },
    experiments: { typedRoutes: true }
} satisfies ExpoConfig
