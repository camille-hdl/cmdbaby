import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le catalogue contient 56 katakana, 10 chiffres et les symboles, sans doublon")
func terminalGlyphCatalogListsMatrixGlyphsOnce() {
  let katakana = (0xFF66...0xFF9D).map { Character(Unicode.Scalar($0)!) }
  let digits = Array("0123456789")
  let symbols: [Character] = [":", ".", "\"", "=", "*", "+", "-", "<", ">", "¦", "|"]
  let expected = katakana + digits + symbols

  #expect(katakana.count == 56)
  #expect(digits.count == 10)
  #expect(TerminalGlyphCatalog.glyphs == expected)
  #expect(Set(TerminalGlyphCatalog.glyphs).count == expected.count)
}
