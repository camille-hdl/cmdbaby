import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le catalogue expose le mode océan par défaut")
func playModeCatalogDefaultsToOcean() {
  #expect(KioskPlayModeCatalog.available == [.ocean, .galaxy])
  #expect(KioskPlayModeCatalog.default == .ocean)
  #expect(KioskPlayModeCatalog.displayName(.ocean) == "Océan")
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

@Test("Le champ d’étoiles privilégie les étoiles, avec quelques objets rares")
func warpFieldCatalogPrefersStars() {
  #expect(WarpFieldCatalog.emoji(roll: 0.07, starIndex: 0, rareIndex: 1) == WarpFieldCatalog.rare[1])
  #expect(WarpFieldCatalog.emoji(roll: 0.08, starIndex: 2, rareIndex: 0) == WarpFieldCatalog.stars[2])
}

@Test("La vitesse max vaut cinq fois la vitesse de repos")
func warpDriveMaxIsFiveTimesRest() {
  #expect(WarpDrive.maxSpeed == WarpDrive.rest * 5)
}

@Test("Une frappe accélère, l’arrêt ramène à la vitesse de repos")
func warpDriveAcceleratesThenDecays() {
  var drive = WarpDrive(now: 0)
  #expect(drive.speed == WarpDrive.rest)
  drive.impulse(at: 1)
  let boosted = drive.speed
  #expect(boosted > WarpDrive.rest)
  drive.impulse(at: 1.05)
  let faster = drive.speed
  #expect(faster > boosted)
  drive.tick(now: 1.1, dt: 0.5)
  #expect(drive.speed == faster)
  drive.tick(now: 1.05 + WarpDrive.idleDelay + 0.01, dt: 2)
  #expect(drive.speed == WarpDrive.rest)
}

@Test("La vitesse de défilement est plafonnée")
func warpDriveIsCapped() {
  var drive = WarpDrive(now: 0)
  for step in 0..<40 {
    drive.impulse(at: Double(step) * 0.05)
  }
  #expect(drive.speed == WarpDrive.maxSpeed)
}
