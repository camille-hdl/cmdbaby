// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "BabyWork",
  defaultLocalization: "fr",
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
    .target(name: "BabyWorkDiagnosticsKit"),
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
