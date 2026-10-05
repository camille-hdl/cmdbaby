import Foundation

/// Ce que l’app fait au démarrage, avant toute session.
public enum LaunchPlan: Equatable, Sendable {
  case idle
  case openSettings(InitialSettingsSection)

  /// `--open-settings general` ouvre Général. Sinon, premier lancement : Sorties.
  /// Une configuration déjà enregistrée, sans cet argument, ne change rien.
  public static func atLaunch(hasSavedConfiguration: Bool, arguments: [String] = []) -> LaunchPlan {
    if requestedSection(in: arguments) == .general {
      return .openSettings(.general)
    }
    if hasSavedConfiguration {
      return .idle
    }
    return .openSettings(.exits)
  }

  /// `general` juste après `--open-settings`. Toute autre valeur est ignorée.
  private static func requestedSection(in arguments: [String]) -> InitialSettingsSection? {
    guard let flag = arguments.firstIndex(of: "--open-settings") else { return nil }
    let value = arguments.index(after: flag)
    guard arguments.indices.contains(value), arguments[value] == "general" else { return nil }
    return .general
  }
}
