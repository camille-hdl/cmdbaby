// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "BabyWork",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "BabyWorkDiagnosticsKit",
      targets: ["BabyWorkDiagnosticsKit"]
    ),
    .executable(
      name: "BabyWorks",
      targets: ["BabyWorks"]
    ),
  ],
  targets: [
    .target(
      name: "BabyWorkDiagnosticsKit",
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "BabyWorkAppKitBridge",
      publicHeadersPath: "include",
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("ApplicationServices"),
        .linkedFramework("CoreFoundation"),
        .linkedFramework("CoreGraphics"),
      ]
    ),
    .executableTarget(
      name: "BabyWorks",
      dependencies: ["BabyWorkDiagnosticsKit", "BabyWorkAppKitBridge"],
      resources: [
        .process("Resources/Ocean"),
        .process("Resources/Starship"),
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
      name: "BabyWorkDiagnosticsKitTests",
      dependencies: ["BabyWorkDiagnosticsKit", "BabyWorkAppKitBridge"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
