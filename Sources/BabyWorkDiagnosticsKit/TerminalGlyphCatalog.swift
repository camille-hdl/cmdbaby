import Foundation

/// Glyphes de la pluie : katakana demi-chasse, chiffres et symboles du film.
public enum TerminalGlyphCatalog: Sendable {
  /// `U+FF66…U+FF9D`, puis `0…9`, puis `: . " = * + - < > ¦ |`.
  public static let glyphs: [Character] = {
    let katakana = (0xFF66...0xFF9D).compactMap { Unicode.Scalar($0).map(Character.init) }
    let digits = Array("0123456789")
    let symbols: [Character] = [":", ".", "\"", "=", "*", "+", "-", "<", ">", "¦", "|"]
    return katakana + digits + symbols
  }()
}
