import Foundation

/// Ce que l’app fait au démarrage, avant toute session.
public enum LaunchPlan: Equatable, Sendable {
  case idle
  case openSettings(InitialSettingsSection)

  /// Premier lancement : aucune configuration enregistrée. Sinon, rien à ouvrir.
  public static func atLaunch(hasSavedConfiguration: Bool) -> LaunchPlan {
    if hasSavedConfiguration {
      .idle
    } else {
      .openSettings(.exits)
    }
  }
}
