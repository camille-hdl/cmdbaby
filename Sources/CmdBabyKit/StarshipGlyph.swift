import Foundation

/// Glyphe affiché sur une cible pour la frappe qui l’a fait surgir.
public enum StarshipGlyph: Sendable {
  /// Texte à afficher sur la cible pour `NSEvent.characters`. `nil` = cible sans glyphe.
  public static func label(for characters: String?) -> String? {
    guard let character = characters?.first else { return nil }
    if character.isLetter {
      return String(character).uppercased()
    }
    if character.isNumber || character.isPunctuation || character.isSymbol {
      return String(character)
    }
    return nil
  }
}
