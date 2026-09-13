import Foundation

/// Modes jouables du kiosk. D’autres identifiants s’ajouteront (feuille, paysage, jeux)
/// sans changer le confinement ni les sorties adultes.
public enum KioskPlayModeID: String, Sendable, CaseIterable, Equatable {
  case galaxy
}

public enum KioskPlayModeCatalog: Sendable {
  public static var available: [KioskPlayModeID] { [.galaxy] }

  public static var `default`: KioskPlayModeID { .galaxy }

  public static func displayName(_ id: KioskPlayModeID) -> String {
    switch id {
    case .galaxy:
      "Galaxie"
    }
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
