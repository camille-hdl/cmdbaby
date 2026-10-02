import Foundation

/// Modes jouables du kiosk. Océan est le mode par défaut ; d’autres identifiants
/// s’ajouteront (feuille, paysage, jeux)
/// sans changer le confinement ni les sorties adultes.
public enum KioskPlayModeID: String, Codable, Sendable, CaseIterable, Equatable {
  case ocean
  case galaxy
}

public enum KioskPlayModeCatalog: Sendable {
  /// Ordre d’affichage = ordre des cas de `KioskPlayModeID`.
  public static var available: [KioskPlayModeID] { KioskPlayModeID.allCases }

  public static var `default`: KioskPlayModeID { .ocean }

  public static func displayName(_ id: KioskPlayModeID) -> String {
    switch id {
    case .ocean:
      "Océan"
    case .galaxy:
      "Galaxie"
    }
  }

  /// Phrase courte pour la carte de Réglages.
  public static func tagline(_ id: KioskPlayModeID) -> String {
    switch id {
    case .ocean:
      "Des poissons, du sable et des bulles à chaque touche."
    case .galaxy:
      "Des lettres et des étoiles qui filent dans l’espace."
    }
  }

  /// Identifiant brut → mode enregistré ; `nil` si inconnu, sans repli silencieux.
  public static func resolve(_ id: String) -> KioskPlayModeID? {
    available.first { $0.rawValue == id }
  }

  /// Mode de session pour une clé de config : identifiant enregistré, sinon Océan.
  public static func sessionMode(fromRawID id: String) -> KioskPlayModeID {
    resolve(id) ?? `default`
  }
}

public enum PlayGlyph: Equatable, Sendable {
  case character(Character)
  case emoji(String)

  public var displayText: String {
    switch self {
    case .character(let character):
      String(character)
    case .emoji(let emoji):
      emoji
    }
  }
}

/// Décide ce qui apparaît pour une frappe, sans journaliser le caractère.
public enum PlayGlyphResolver: Sendable {
  public static let emojis = [
    "⭐️", "🌟", "✨", "🌙", "🚀", "🪐", "👽", "🛸", "🌈", "🦄",
    "🐱", "🐶", "🎈", "🍀", "🍓", "🌸", "🐠", "🦋", "☁️", "❄️",
  ]

  public static func glyph(fromVisibleCharacter character: Character?, emojiIndex: Int) -> PlayGlyph {
    if let character, character.isLetter {
      let upper = String(character).uppercased()
      return .character(upper.first ?? character)
    }
    if let character, character.isNumber {
      return .character(character)
    }
    let index = abs(emojiIndex) % emojis.count
    return .emoji(emojis[index])
  }
}

/// Emojis du champ d’étoiles en perspective.
public enum WarpFieldCatalog: Sendable {
  public static let stars = ["⭐️", "🌟", "✨", "💫"]
  public static let rare = ["🌙", "🪐", "🌑", "☄️", "🛸", "🌍"]
  public static let rareProbability = 0.08

  public static func emoji(roll: Double, starIndex: Int, rareIndex: Int) -> String {
    if roll < rareProbability {
      return rare[abs(rareIndex) % rare.count]
    }
    return stars[abs(starIndex) % stars.count]
  }
}

/// Vitesse de défilement : accélère à chaque frappe, ralentit à l’arrêt.
public struct WarpDrive: Equatable, Sendable {
  public static let rest = 1.0 / 6.0
  public static let maxSpeed = rest * 5
  public static let boostPerKey = 0.32 / 6.0
  public static let decayPerSecond = 1.35 / 6.0
  public static let idleDelay: TimeInterval = 0.2

  public private(set) var speed: Double
  public private(set) var lastImpulseAt: TimeInterval

  public init(now: TimeInterval = 0, speed: Double = WarpDrive.rest) {
    self.speed = Swift.max(Self.rest, Swift.min(Self.maxSpeed, speed))
    self.lastImpulseAt = now
  }

  public mutating func impulse(at now: TimeInterval) {
    lastImpulseAt = now
    speed = Swift.min(Self.maxSpeed, speed + Self.boostPerKey)
  }

  public mutating func tick(now: TimeInterval, dt: TimeInterval) {
    let clampedDt = Swift.max(0, dt)
    guard now - lastImpulseAt >= Self.idleDelay else { return }
    speed = Swift.max(Self.rest, speed - Self.decayPerSecond * clampedDt)
  }
}
