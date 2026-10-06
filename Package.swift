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
      dependencies: ["CmdBabyKit", "CmdBabyAppKitBridge"],
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
      dependencies: ["CmdBabyKit", "CmdBabyAppKitBridge"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
