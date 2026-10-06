/// Variante du logo des Réglages, d’après l’apparence de la fenêtre.
public enum AppLogoVariant: Equatable, Sendable {
  case jour
  case nuit

  public static func `for`(colorSchemeIsDark: Bool) -> AppLogoVariant {
    colorSchemeIsDark ? .nuit : .jour
  }

  /// PDF vectoriel sans ombre, dans les ressources de l’app.
  public var resourceName: String {
    switch self {
    case .jour: "AppLogo-jour"
    case .nuit: "AppLogo-nuit"
    }
  }
}
