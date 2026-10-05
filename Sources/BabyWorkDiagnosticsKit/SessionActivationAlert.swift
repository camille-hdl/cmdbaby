import Foundation

/// Alerte parent quand l’activation de session échoue.
/// Aucune dépendance AppKit — le `NSAlert` vit dans BabyWorks.
public struct SessionActivationAlert: Equatable, Sendable {
  public let title: String
  public let informativeText: String
  public let actions: [Action]
  /// Section ouverte par « Réglages… ». `nil` garde le routage actuel, Mode de jeu.
  public let settingsSection: InitialSettingsSection?

  public enum Action: Equatable, Sendable {
    case openAccessibilitySettings
    case openAppSettings
    case dismiss

    public var title: String {
      switch self {
      case .openAccessibilitySettings:
        "Ouvrir Accessibilité"
      case .openAppSettings:
        "Réglages…"
      case .dismiss:
        "OK"
      }
    }
  }

  public static let accessibilitySettingsURLCandidates = [
    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
  ]

  public static func forFailedActivation(
    _ error: KioskSessionError,
    runningBinaryURL: URL? = nil,
    table: L10nTable = .current
  ) -> SessionActivationAlert {
    SessionActivationAlert(
      title: "La session n’a pas pu démarrer",
      informativeText: informativeText(
        for: error,
        runningBinaryURL: runningBinaryURL,
        table: table
      ),
      actions: actions(for: error),
      settingsSection: settingsSection(for: error)
    )
  }

  private static func informativeText(
    for error: KioskSessionError,
    runningBinaryURL: URL?,
    table: L10nTable
  ) -> String {
    switch error {
    case .filterUnavailable(let reason):
      filterUnavailableText(reason: reason, runningBinaryURL: runningBinaryURL)
    case .noScreens:
      "Aucun écran n’est disponible pour la couverture."
    case .presentationRejected:
      "Les options de présentation kiosque ont été refusées. Relancez l’application et réessayez."
    case .injectedFailure:
      "La session n’a pas pu démarrer. Réessayez depuis le menu."
    case .passphraseNotTypable(let letters):
      passphraseNotTypableText(letters, table: table)
    }
  }

  private static func filterUnavailableText(reason: String, runningBinaryURL: URL?) -> String {
    var lines = [
      "BabyWorks n’a pas pu activer le kiosque (\(reason))."
    ]
    if let runningBinaryURL {
      lines.append("Binaire actuel : \(runningBinaryURL.path)")
    }
    lines.append(
      "Retirez les anciennes entrées BabyWorks dans Réglages système → Accessibilité, puis ré-autorisez cette copie. Une signature ad hoc invalide l’identité TCC à chaque rebuild."
    )
    lines.append(
      "Accordez Accessibilité, puis quittez et relancez l’application."
    )
    return lines.joined(separator: "\n\n")
  }

  private static func actions(for error: KioskSessionError) -> [Action] {
    switch error {
    case .filterUnavailable:
      [.openAccessibilitySettings, .openAppSettings, .dismiss]
    case .noScreens, .presentationRejected, .injectedFailure, .passphraseNotTypable:
      [.openAppSettings, .dismiss]
    }
  }

  private static func settingsSection(for error: KioskSessionError) -> InitialSettingsSection? {
    switch error {
    case .passphraseNotTypable:
      .exits
    case .filterUnavailable, .noScreens, .presentationRejected, .injectedFailure:
      nil
    }
  }

  static func passphraseNotTypableText(_ letters: [Character], table: L10nTable) -> String {
    table(
      "alert.passphraseNotTypable",
      letters.map(String.init).joined(separator: " ")
    )
  }
}
