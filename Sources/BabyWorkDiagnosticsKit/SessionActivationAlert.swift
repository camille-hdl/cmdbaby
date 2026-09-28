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

  public static func forFailedActivation(_ error: KioskSessionError) -> SessionActivationAlert {
    SessionActivationAlert(
      title: "La session n’a pas pu démarrer",
      informativeText: informativeText(for: error),
      actions: actions(for: error)
    )
  }

  private static func informativeText(for error: KioskSessionError) -> String {
    switch error {
    case .filterUnavailable:
      "BabyWorks n’a pas pu activer le kiosque. Accordez Accessibilité dans Réglages système, puis quittez et relancez l’application."
    case .noScreens:
      "Aucun écran n’est disponible pour la couverture."
    case .presentationRejected:
      "Les options de présentation kiosque ont été refusées. Relancez l’application et réessayez."
    case .injectedFailure:
      "La session n’a pas pu démarrer. Réessayez depuis le menu."
    }
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
