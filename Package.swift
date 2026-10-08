// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "CmdBaby",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "CmdBabyKit",
      targets: ["CmdBabyKit"]
    ),
    .executable(
      name: "CmdBaby",
      targets: ["CmdBaby"]
    ),
  ],
  dependencies: [
    // Mises à jour (#102). Version exacte : Package.resolved est commité, release.sh le fige.
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
  ],
  targets: [
    .target(
      name: "CmdBabyKit",
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "CmdBabyAppKitBridge",
      publicHeadersPath: "include",
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("ApplicationServices"),
        .linkedFramework("CoreFoundation"),
        .linkedFramework("CoreGraphics"),
      ]
    ),
    .executableTarget(
      name: "CmdBaby",
      dependencies: [
        "CmdBabyKit",
        "CmdBabyAppKitBridge",
        .product(name: "Sparkle", package: "Sparkle"),
      ],
      resources: [
        .process("Resources/Ocean"),
        .process("Resources/Starship"),
        .process("Resources/Brand"),
      ],
      linkerSettings: [
        .linkedFramework("ApplicationServices"),
        .linkedFramework("AppKit"),
        .linkedFramework("Carbon"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("IOKit"),
        .linkedFramework("ServiceManagement"),
        .linkedFramework("SwiftUI"),
      ]
    ),
    .testTarget(
      name: "CmdBabyKitTests",
      dependencies: ["CmdBabyKit", "CmdBabyAppKitBridge", "CmdBaby"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
