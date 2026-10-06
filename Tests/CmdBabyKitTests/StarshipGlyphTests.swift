import Testing

@testable import CmdBabyKit

@Test("Le glyphe d’une lettre est sa majuscule, chiffres et symboles restent tels quels")
func starshipGlyphShowsTheKey() {
  #expect(StarshipGlyph.label(for: "a") == "A")
  #expect(StarshipGlyph.label(for: "é") == "É")
  #expect(StarshipGlyph.label(for: "7") == "7")
  #expect(StarshipGlyph.label(for: "&") == "&")
  #expect(StarshipGlyph.label(for: "€") == "€")
  #expect(StarshipGlyph.label(for: "?") == "?")
  #expect(StarshipGlyph.label(for: "ab") == "A")
}

@Test("Une frappe sans glyphe affichable n’en porte pas")
func starshipGlyphOmitsControlsAndEmptyInput() {
  #expect(StarshipGlyph.label(for: nil) == nil)
  #expect(StarshipGlyph.label(for: "") == nil)
  #expect(StarshipGlyph.label(for: "\r") == nil)
  #expect(StarshipGlyph.label(for: "\t") == nil)
  #expect(StarshipGlyph.label(for: "\u{7F}") == nil)
  #expect(StarshipGlyph.label(for: "\u{F700}") == nil)
}
