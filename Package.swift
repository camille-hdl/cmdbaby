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
    .executableTarget(
      name: "BabyWorkDiagnostics",
      dependencies: ["BabyWorkDiagnosticsKit"],
      linkerSettings: [
        .linkedFramework("ApplicationServices"),
        .linkedFramework("AppKit"),
        .linkedFramework("CoreGraphics"),
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
