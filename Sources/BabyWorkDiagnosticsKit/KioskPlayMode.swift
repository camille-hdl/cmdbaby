/// Modes jouables du kiosk. Océan est le mode par défaut ; d’autres identifiants
/// s’ajouteront (feuille, paysage, jeux)
/// sans changer le confinement ni les sorties adultes.
public enum KioskPlayModeID: String, Codable, Sendable, CaseIterable, Equatable {
  case ocean
  case terminal
  case starship
}

public enum KioskPlayModeCatalog: Sendable {
  /// Ordre d’affichage = ordre des cas de `KioskPlayModeID`.
  public static var available: [KioskPlayModeID] { KioskPlayModeID.allCases }

  public static var `default`: KioskPlayModeID { .ocean }

  /// Identifiants retirés → mode qui les remplace.
  private static let retiredModes: [String: KioskPlayModeID] = ["galaxy": .starship]

  public static func displayName(_ id: KioskPlayModeID) -> String {
    switch id {
    case .ocean:
      "Océan"
    case .terminal:
      "Terminal"
    case .starship:
      "Vaisseau"
    }
  }

  /// Phrase courte pour la carte de Réglages.
  public static func tagline(_ id: KioskPlayModeID) -> String {
    switch id {
    case .ocean:
      "Des poissons, du sable et des bulles à chaque touche."
    case .terminal:
      "Tape au clavier et fais pleuvoir le code vert."
    case .starship:
      "Chaque touche fait surgir un intrus, ton vaisseau le pulvérise au laser."
    }
  }

  /// Identifiant brut → mode enregistré ; `nil` si inconnu, sans repli silencieux.
  public static func resolve(_ id: String) -> KioskPlayModeID? {
    available.first { $0.rawValue == id }
  }

  /// Mode de session pour une clé de config : identifiant encore proposé,
  /// sinon identifiant retiré traduit, sinon Océan.
  public static func sessionMode(fromRawID id: String) -> KioskPlayModeID {
    resolve(id) ?? retiredModes[id] ?? `default`
  }
}
