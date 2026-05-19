// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CmdScrollZoom",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "cmd-scroll-zoom", targets: ["CmdScrollZoom"])
    ],
    targets: [
        .executableTarget(
            name: "CmdScrollZoom",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
