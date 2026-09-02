import AppKit
import ApplicationServices
import BabyWorkDiagnosticsKit
import CoreGraphics
import Foundation

@MainActor
enum SystemSnapshotCollector {
  static func capture() -> DiagnosticSnapshot {
    let developerDirectory = command(
      executable: "/usr/bin/xcode-select",
      arguments: ["-p"]
    ).outputOrFallback("Indisponible")

    let xcode = command(executable: "/usr/bin/xcodebuild", arguments: ["-version"])
    let xcodeVersion =
      xcode.succeeded
      ? xcode.output.replacingOccurrences(of: "\n", with: " — ")
      : "Indisponible (\(developerToolLabel(for: developerDirectory)))"

    let processInfo = ProcessInfo.processInfo
    let version = processInfo.operatingSystemVersion

    return DiagnosticSnapshot(
      macOSVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
      macOSBuild: command(
        executable: "/usr/bin/sw_vers",
        arguments: ["-buildVersion"]
      ).outputOrFallback("build inconnu"),
      architecture: architecture,
      xcodeVersion: xcodeVersion,
      developerDirectory: developerDirectory,
      bundleIdentifier: Bundle.main.bundleIdentifier ?? "Exécution SwiftPM non empaquetée",
      signingIdentity: Bundle.main.object(
        forInfoDictionaryKey: "BabyWorkSigningIdentity"
      ) as? String ?? "Exécution SwiftPM non signée",
      displays: NSScreen.screens.map { screen in
        DisplaySnapshot(
          name: screen.localizedName,
          width: Int(screen.frame.width.rounded()),
          height: Int(screen.frame.height.rounded()),
          scale: screen.backingScaleFactor,
          isMain: screen === NSScreen.main
        )
      },
      inputMonitoringGranted: CGPreflightListenEventAccess(),
      accessibilityGranted: AXIsProcessTrusted()
    )
  }

  private static var architecture: String {
    #if arch(arm64)
      "arm64"
    #elseif arch(x86_64)
      "x86_64"
    #else
      "Architecture inconnue"
    #endif
  }

  private static func developerToolLabel(for path: String) -> String {
    path.contains("CommandLineTools") ? "Command Line Tools actifs" : "Xcode indisponible"
  }

  private static func command(executable: String, arguments: [String]) -> CommandResult {
    let process = Process()
    let output = Pipe()

    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = output

    do {
      try process.run()
      process.waitUntilExit()
      let data = output.fileHandleForReading.readDataToEndOfFile()
      let text = String(decoding: data, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      return CommandResult(output: text, succeeded: process.terminationStatus == 0)
    } catch {
      return CommandResult(output: error.localizedDescription, succeeded: false)
    }
  }
}

private struct CommandResult {
  let output: String
  let succeeded: Bool

  func outputOrFallback(_ fallback: String) -> String {
    output.isEmpty ? fallback : output
  }
}
