import Foundation

/// Alerte parent quand l’activation de session échoue.
/// Aucune dépendance AppKit — le `NSAlert` vit dans BabyWorks.
public struct SessionActivationAlert: Equatable, Sendable {
  public let title: String
  public let informativeText: String
  public let actions: [Action]

  public enum Action: Equatable, Sendable {
    case openAppSettings(InitialSettingsSection)
    case dismiss

    public func title(in table: L10nTable = .current) -> String {
      switch self {
      case .openAppSettings:
        table("alert.action.settings")
      case .dismiss:
        table("alert.action.ok")
      }
    }
  }

  public static let accessibilitySettingsURLCandidates = [
    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
  ]

  public static func forFailedActivation(
    _ error: KioskSessionError,
    table: L10nTable = .current
  ) -> SessionActivationAlert {
    SessionActivationAlert(
      title: table("alert.title"),
      informativeText: informativeText(for: error, table: table),
      actions: actions(for: error)
    )
  }

  private static func informativeText(for error: KioskSessionError, table: L10nTable) -> String {
    switch error {
    case .filterUnavailable:
      table("alert.filterUnavailable")
    case .noScreens:
      table("alert.noScreens")
    case .presentationRejected:
      table("alert.presentationRejected")
    case .injectedFailure:
      table("alert.injectedFailure")
    case .passphraseNotTypable(let letters):
      passphraseNotTypableText(letters, table: table)
    }
  }

  private static func actions(for error: KioskSessionError) -> [Action] {
    switch error {
    case .filterUnavailable:
      [.openAppSettings(.permissions), .dismiss]
    case .passphraseNotTypable:
      [.openAppSettings(.exits), .dismiss]
    case .noScreens, .presentationRejected, .injectedFailure:
      [.openAppSettings(.mode), .dismiss]
    }
  }

  /// Motif technique et chemin du binaire, pour le journal. Jamais la phrase ni ses lettres.
  public static func activationFailureLog(
    _ error: KioskSessionError,
    binaryPath: String
  ) -> LifecycleLogEvent {
    .sessionActivationFail(reason: journalReason(for: error), binaryPath: binaryPath)
  }

  private static func journalReason(for error: KioskSessionError) -> String {
    switch error {
    case .filterUnavailable(let reason):
      reason
    case .noScreens:
      "noScreens"
    case .presentationRejected:
      "presentationRejected"
    case .injectedFailure(let step):
      "injectedFailure \(step.rawValue)"
    case .passphraseNotTypable:
      "passphraseNotTypable"
    }
  }

  static func passphraseNotTypableText(_ letters: [Character], table: L10nTable) -> String {
    table(
      "alert.passphraseNotTypable",
      letters.map(String.init).joined(separator: " ")
    )
  }
}
