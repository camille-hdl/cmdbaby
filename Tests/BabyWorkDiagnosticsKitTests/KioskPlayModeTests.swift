import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le catalogue expose le mode océan par défaut")
func playModeCatalogDefaultsToOcean() {
  #expect(KioskPlayModeCatalog.available == [.ocean, .terminal, .starship])
  #expect(KioskPlayModeCatalog.default == .ocean)
}

@Test("Les noms et les phrases des modes sont en anglais et en français")
func playModeCatalogNamesAndTaglinesFollowTheLanguage() {
  let french = L10nTable.language("fr")
  let english = L10nTable.language("en")

  #expect(KioskPlayModeCatalog.displayName(.ocean, in: french) == "Océan")
  #expect(KioskPlayModeCatalog.displayName(.terminal, in: french) == "Terminal")
  #expect(KioskPlayModeCatalog.displayName(.starship, in: french) == "Vaisseau")
  #expect(KioskPlayModeCatalog.displayName(.ocean, in: english) == "Ocean")
  #expect(KioskPlayModeCatalog.displayName(.terminal, in: english) == "Terminal")
  #expect(KioskPlayModeCatalog.displayName(.starship, in: english) == "Starship")

  #expect(KioskPlayModeCatalog.tagline(.ocean, in: french) == "Des poissons, du sable et des bulles à chaque touche.")
  #expect(KioskPlayModeCatalog.tagline(.terminal, in: french) == "Tape au clavier et fais pleuvoir le code vert.")
  #expect(
    KioskPlayModeCatalog.tagline(.starship, in: french)
      == "Chaque touche fait surgir un intrus, ton vaisseau le pulvérise au laser."
  )
  #expect(KioskPlayModeCatalog.tagline(.ocean, in: english) == "Fish, sand, and bubbles with every key.")
  #expect(KioskPlayModeCatalog.tagline(.terminal, in: english) == "Type on the keyboard and make green code rain.")
  #expect(
    KioskPlayModeCatalog.tagline(.starship, in: english)
      == "Every key summons an intruder, and your starship blasts it with a laser."
  )
}

@Test("Les modes affichés suivent l’ordre des cas")
func playModeCatalogAvailableMatchesAllCases() {
  #expect(KioskPlayModeCatalog.available == Array(KioskPlayModeID.allCases))
}

@Test("Le registre résout Océan, Terminal et Vaisseau par identifiant")
func playModeCatalogResolvesRegisteredIDs() {
  #expect(KioskPlayModeCatalog.resolve("ocean") == .ocean)
  #expect(KioskPlayModeCatalog.resolve("terminal") == .terminal)
  #expect(KioskPlayModeCatalog.resolve("starship") == .starship)
}

@Test("Un identifiant de mode inconnu n’est pas résolu")
func playModeCatalogRejectsUnknownID() {
  #expect(KioskPlayModeCatalog.resolve("leaf") == nil)
  #expect(KioskPlayModeCatalog.resolve("") == nil)
}

@Test("Un identifiant Galaxie enregistré ouvre le mode Vaisseau")
func retiredGalaxyIdentifierOpensStarship() {
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "galaxy") == .starship)
  #expect(KioskPlayModeCatalog.resolve("galaxy") == nil)
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "inconnu") == .ocean)
}

@Test("Le mode de session suit l’identifiant enregistré, sinon Océan")
func playModeCatalogSessionModeFallsBackToOcean() {
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "ocean") == .ocean)
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "terminal") == .terminal)
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "starship") == .starship)
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "leaf") == .ocean)
  #expect(KioskPlayModeCatalog.sessionMode(fromRawID: "") == .ocean)
}
