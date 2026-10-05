import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le catalogue expose le mode océan par défaut")
func playModeCatalogDefaultsToOcean() {
  #expect(KioskPlayModeCatalog.available == [.ocean, .terminal, .starship])
  #expect(KioskPlayModeCatalog.default == .ocean)
  #expect(KioskPlayModeCatalog.displayName(.ocean) == "Océan")
  #expect(KioskPlayModeCatalog.displayName(.terminal) == "Terminal")
  #expect(KioskPlayModeCatalog.displayName(.starship) == "Vaisseau")
}

@Test("Les modes affichés suivent l’ordre des cas")
func playModeCatalogAvailableMatchesAllCases() {
  #expect(KioskPlayModeCatalog.available == Array(KioskPlayModeID.allCases))
}

@Test("Chaque mode a une phrase courte pour la carte de Réglages")
func playModeCatalogTaglineIsPresentForEveryMode() {
  #expect(KioskPlayModeCatalog.tagline(.ocean) == "Des poissons, du sable et des bulles à chaque touche.")
  #expect(KioskPlayModeCatalog.tagline(.terminal) == "Tape au clavier et fais pleuvoir le code vert.")
  #expect(KioskPlayModeCatalog.tagline(.starship) == "Chaque touche fait surgir un intrus, ton vaisseau le pulvérise au laser.")
  for id in KioskPlayModeID.allCases {
    #expect(!KioskPlayModeCatalog.tagline(id).isEmpty)
  }
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
