// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ZHHCarouselView",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ZHHCarouselView", targets: ["ZHHCarouselView"])
    ],
    targets: [
        .target(
            name: "ZHHCarouselView",
            path: "ZHHCarouselView",
            exclude: ["Assets"],
            sources: ["Classes"],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
