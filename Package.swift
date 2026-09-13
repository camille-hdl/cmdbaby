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
      name: "BabyWorkDiagnostics",
      targets: ["BabyWorkDiagnostics"]
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
      name: "BabyWorkDiagnostics",
      dependencies: ["BabyWorkDiagnosticsKit", "BabyWorkAppKitBridge"],
      linkerSettings: [
        .linkedFramework("ApplicationServices"),
        .linkedFramework("AppKit"),
        .linkedFramework("Carbon"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("IOKit"),
        .linkedFramework("SwiftUI"),
      ]
    ),
    .testTarget(
      name: "BabyWorkDiagnosticsKitTests",
      dependencies: ["BabyWorkDiagnosticsKit"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
