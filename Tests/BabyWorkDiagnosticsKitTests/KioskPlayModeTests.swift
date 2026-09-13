import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le catalogue expose le mode galaxie par défaut")
func playModeCatalogStartsWithGalaxy() {
  #expect(KioskPlayModeCatalog.available == [.galaxy])
  #expect(KioskPlayModeCatalog.default == .galaxy)
  #expect(KioskPlayModeCatalog.displayName(.galaxy) == "Galaxie")
}

@Test("Une lettre devient un glyphe majuscule")
func letterBecomesUppercaseGlyph() {
  #expect(PlayGlyphResolver.glyph(fromVisibleCharacter: "a", emojiIndex: 0) == .character("A"))
  #expect(PlayGlyphResolver.glyph(fromVisibleCharacter: "é", emojiIndex: 0) == .character("É"))
}

@Test("Un chiffre est affiché tel quel")
func digitBecomesGlyph() {
  #expect(PlayGlyphResolver.glyph(fromVisibleCharacter: "7", emojiIndex: 0) == .character("7"))
}

@Test("Une touche sans lettre ni chiffre devient un emoji du catalogue")
func nonAlphanumericBecomesEmoji() {
  let glyph = PlayGlyphResolver.glyph(fromVisibleCharacter: "&", emojiIndex: 2)
  #expect(glyph == .emoji(PlayGlyphResolver.emojis[2]))
  #expect(PlayGlyphResolver.glyph(fromVisibleCharacter: nil, emojiIndex: 0) == .emoji(PlayGlyphResolver.emojis[0]))
}

@Test("L’indice d’emoji boucle dans le catalogue")
func emojiIndexWraps() {
  let count = PlayGlyphResolver.emojis.count
  #expect(
    PlayGlyphResolver.glyph(fromVisibleCharacter: nil, emojiIndex: count)
      == .emoji(PlayGlyphResolver.emojis[0])
  )
}
