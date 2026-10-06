import Foundation

public struct DiagnosticSnapshot: Equatable, Sendable {
  public let macOSVersion: String
  public let macOSBuild: String
  public let architecture: String
  public let xcodeVersion: String
  public let developerDirectory: String
  public let bundleIdentifier: String
  public let signingIdentity: String
  public let bundleLocation: String
  public let displays: [DisplaySnapshot]
  public let inputMonitoringListenGranted: Bool
  public let inputMonitoringPostGranted: Bool
  public let accessibilityGranted: Bool

  public var inputMonitoringGranted: Bool {
    inputMonitoringListenGranted || inputMonitoringPostGranted
  }

  public init(
    macOSVersion: String,
    macOSBuild: String,
    architecture: String,
    xcodeVersion: String,
    developerDirectory: String,
    bundleIdentifier: String,
    signingIdentity: String,
    bundleLocation: String,
    displays: [DisplaySnapshot],
    inputMonitoringListenGranted: Bool,
    inputMonitoringPostGranted: Bool = false,
    accessibilityGranted: Bool
  ) {
    self.macOSVersion = macOSVersion
    self.macOSBuild = macOSBuild
    self.architecture = architecture
    self.xcodeVersion = xcodeVersion
    self.developerDirectory = developerDirectory
    self.bundleIdentifier = bundleIdentifier
    self.signingIdentity = signingIdentity
    self.bundleLocation = bundleLocation
    self.displays = displays
    self.inputMonitoringListenGranted = inputMonitoringListenGranted
    self.inputMonitoringPostGranted = inputMonitoringPostGranted
    self.accessibilityGranted = accessibilityGranted
  }
}

public struct DisplaySnapshot: Equatable, Sendable {
  public let name: String
  public let width: Int
  public let height: Int
  public let scale: Double
  public let isMain: Bool

  public init(name: String, width: Int, height: Int, scale: Double, isMain: Bool) {
    self.name = name
    self.width = width
    self.height = height
    self.scale = scale
    self.isMain = isMain
  }
}

public struct DiagnosticReport: Equatable, Sendable {
  public let sections: [DiagnosticSection]

  public init(snapshot: DiagnosticSnapshot) {
    sections = [
      DiagnosticSection(
        title: "Système",
        rows: [
          DiagnosticRow(
            label: "macOS",
            value: "\(snapshot.macOSVersion) (\(snapshot.macOSBuild))"
          ),
          DiagnosticRow(label: "Architecture", value: snapshot.architecture),
          DiagnosticRow(label: "Xcode", value: snapshot.xcodeVersion),
          DiagnosticRow(
            label: "Outils développeur",
            value: snapshot.developerDirectory
          ),
        ]
      ),
      DiagnosticSection(
        title: "Signature",
        rows: [
          DiagnosticRow(label: "Bundle ID", value: snapshot.bundleIdentifier),
          DiagnosticRow(label: "Identité", value: snapshot.signingIdentity),
          DiagnosticRow(label: "Emplacement", value: snapshot.bundleLocation),
        ]
      ),
      DiagnosticSection(
        title: "Écrans",
        rows: snapshot.displays.isEmpty
          ? [
            DiagnosticRow(
              label: "Détection",
              value: "Aucun écran détecté",
              state: .attention
            )
          ]
          : snapshot.displays.enumerated().map { index, display in
            let label =
              display.isMain
              ? "Écran principal — \(display.name)"
              : "Écran \(index + 1) — \(display.name)"
            return DiagnosticRow(
              label: label,
              value: "\(display.width) × \(display.height) pt — échelle \(display.scaleText)×"
            )
          }
      ),
      DiagnosticSection(
        title: "Permissions",
        rows: [
          DiagnosticRow(
            label: "Surveillance de l’entrée (écoute)",
            value: snapshot.inputMonitoringListenGranted
              ? "Accordée"
              : "Non accordée — absente de la liste ou non relancée",
            state: snapshot.inputMonitoringListenGranted ? .granted : .attention
          ),
          DiagnosticRow(
            label: "Surveillance de l’entrée (modification)",
            value: snapshot.inputMonitoringPostGranted
              ? "Accordée"
              : "Non accordée — absente de la liste ou non relancée",
            state: snapshot.inputMonitoringPostGranted ? .granted : .attention
          ),
          DiagnosticRow(
            label: "Accessibilité",
            value: snapshot.accessibilityGranted
              ? "Accordée"
              : "Non vue par ce processus — relancer après l’avoir cochée",
            state: snapshot.accessibilityGranted ? .granted : .attention
          ),
        ]
      ),
    ]
  }
}

public struct DiagnosticSection: Equatable, Sendable {
  public let title: String
  public let rows: [DiagnosticRow]

  public init(title: String, rows: [DiagnosticRow]) {
    self.title = title
    self.rows = rows
  }
}

public struct DiagnosticRow: Equatable, Sendable {
  public let label: String
  public let value: String
  public let state: DiagnosticRowState

  public init(label: String, value: String, state: DiagnosticRowState = .neutral) {
    self.label = label
    self.value = value
    self.state = state
  }
}

public enum DiagnosticRowState: Equatable, Sendable {
  case neutral
  case granted
  case attention
}

extension DisplaySnapshot {
  fileprivate var scaleText: String {
    if scale.rounded() == scale {
      return String(Int(scale))
    }
    return String(format: "%.2f", scale)
      .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
      .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
  }
}
