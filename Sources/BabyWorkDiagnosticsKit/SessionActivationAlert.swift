import Foundation

/// Alerte parent quand l’activation de session échoue.
/// Aucune dépendance AppKit — le `NSAlert` vit dans BabyWorks.
public struct SessionActivationAlert: Equatable, Sendable {
  public let title: String
  public let informativeText: String
  public let actions: [Action]

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
    runningBinaryURL: URL? = nil
  ) -> SessionActivationAlert {
    SessionActivationAlert(
      title: "La session n’a pas pu démarrer",
      informativeText: informativeText(for: error, runningBinaryURL: runningBinaryURL),
      actions: actions(for: error)
    )
  }

  private static func informativeText(
    for error: KioskSessionError,
    runningBinaryURL: URL?
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
    case .noScreens, .presentationRejected, .injectedFailure:
      [.openAppSettings, .dismiss]
    }
  }
}
