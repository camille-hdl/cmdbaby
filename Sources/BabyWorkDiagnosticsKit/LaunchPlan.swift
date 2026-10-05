import Foundation

/// Ce que l’app fait au démarrage, avant toute session.
public enum LaunchPlan: Equatable, Sendable {
  case idle
  case openSettings(InitialSettingsSection)

  /// Argument de relance : rouvre les Réglages sur Général.
  public static let openGeneralSettingsArguments = ["--open-settings", "general"]

  /// Cet argument ouvre Général. Sinon, premier lancement : Sorties.
  /// Une configuration déjà enregistrée, sans cet argument, ne change rien.
  public static func atLaunch(hasSavedConfiguration: Bool, arguments: [String] = []) -> LaunchPlan {
    if opensGeneralSettings(arguments) {
      return .openSettings(.general)
    }
    if hasSavedConfiguration {
      return .idle
    }
    return .openSettings(.exits)
  }

  /// `general` juste après `--open-settings`. Toute autre valeur est ignorée.
  private static func opensGeneralSettings(_ arguments: [String]) -> Bool {
    let marker = openGeneralSettingsArguments
    guard marker.count == 2 else { return false }
    guard let flagIndex = arguments.firstIndex(of: marker[0]) else { return false }
    let valueIndex = arguments.index(after: flagIndex)
    guard arguments.indices.contains(valueIndex) else { return false }
    return arguments[valueIndex] == marker[1]
  }
}
