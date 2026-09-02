import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le diagnostic présente les valeurs système injectées")
func diagnosticPresentsInjectedSystemValues() {
  let snapshot = DiagnosticSnapshot(
    macOSVersion: "15.7.7",
    macOSBuild: "24G720",
    architecture: "arm64",
    xcodeVersion: "Xcode indisponible (Command Line Tools actifs)",
    developerDirectory: "/Library/Developer/CommandLineTools",
    bundleIdentifier: "fr.camille.babywork.diagnostics",
    signingIdentity: "Apple Development: Exemple",
    displays: [
      DisplaySnapshot(
        name: "Écran intégré",
        width: 3_024,
        height: 1_964,
        scale: 2,
        isMain: true
      ),
      DisplaySnapshot(
        name: "Studio Display",
        width: 2_560,
        height: 1_440,
        scale: 1,
        isMain: false
      ),
    ],
    inputMonitoringGranted: true,
    accessibilityGranted: false
  )

  let report = DiagnosticReport(snapshot: snapshot)

  #expect(
    report.sections == [
      DiagnosticSection(
        title: "Système",
        rows: [
          DiagnosticRow(label: "macOS", value: "15.7.7 (24G720)"),
          DiagnosticRow(label: "Architecture", value: "arm64"),
          DiagnosticRow(label: "Xcode", value: "Xcode indisponible (Command Line Tools actifs)"),
          DiagnosticRow(label: "Outils développeur", value: "/Library/Developer/CommandLineTools"),
        ]
      ),
      DiagnosticSection(
        title: "Signature",
        rows: [
          DiagnosticRow(label: "Bundle ID", value: "fr.camille.babywork.diagnostics"),
          DiagnosticRow(label: "Identité", value: "Apple Development: Exemple"),
        ]
      ),
      DiagnosticSection(
        title: "Écrans",
        rows: [
          DiagnosticRow(
            label: "Écran principal — Écran intégré",
            value: "3024 × 1964 pt — échelle 2×"
          ),
          DiagnosticRow(
            label: "Écran 2 — Studio Display",
            value: "2560 × 1440 pt — échelle 1×"
          ),
        ]
      ),
      DiagnosticSection(
        title: "Permissions",
        rows: [
          DiagnosticRow(
            label: "Surveillance de l’entrée",
            value: "Accordée",
            state: .granted
          ),
          DiagnosticRow(
            label: "Accessibilité",
            value: "Non accordée ou indéterminée",
            state: .attention
          ),
        ]
      ),
    ])
}

@Test("Le diagnostic signale qu’aucun écran n’a été détecté")
func diagnosticReportsMissingDisplays() {
  let snapshot = DiagnosticSnapshot(
    macOSVersion: "15.7.7",
    macOSBuild: "24G720",
    architecture: "arm64",
    xcodeVersion: "Indisponible",
    developerDirectory: "/Library/Developer/CommandLineTools",
    bundleIdentifier: "fr.camille.babywork.diagnostics",
    signingIdentity: "Signature ad hoc",
    displays: [],
    inputMonitoringGranted: false,
    accessibilityGranted: false
  )

  let report = DiagnosticReport(snapshot: snapshot)

  #expect(
    report.sections.first(where: { $0.title == "Écrans" })?.rows == [
      DiagnosticRow(
        label: "Détection",
        value: "Aucun écran détecté",
        state: .attention
      )
    ])
}
