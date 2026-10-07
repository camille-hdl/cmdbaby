import Testing

@testable import CmdBabyKit

@Test("Aucune mise à jour ne s’affiche pendant une session")
func updatesWaitForTheSessionToEnd() {
  #expect(UpdatePresentationPolicy.allowsPresentation(sessionActive: true) == false)
  #expect(UpdatePresentationPolicy.allowsPresentation(sessionActive: false) == true)
}

@Test("Le menu de l’app propose « Rechercher les mises à jour… » juste après À propos")
func applicationMenuOffersUpdateCheck() {
  #expect(Array(MenuBarAgent.applicationMenu.map(\.command).prefix(2)) == [.about, .checkForUpdates])
  for language in ["en", "fr"] {
    #expect(L10nTable.language(language)("menu.app.checkForUpdates") != "menu.app.checkForUpdates")
  }
  #expect(L10nTable.language("fr")("menu.app.checkForUpdates") == "Rechercher les mises à jour…")
  #expect(L10nTable.language("en")("menu.app.checkForUpdates") == "Check for Updates…")
}

@Test("Réglages › Général : interrupteur des mises à jour automatiques, traduit")
func automaticUpdatesToggleIsTranslated() {
  #expect(
    L10nTable.language("fr")("settings.general.automaticUpdates.label")
      == "Rechercher automatiquement les mises à jour"
  )
  #expect(
    L10nTable.language("en")("settings.general.automaticUpdates.label")
      == "Check for Updates Automatically"
  )
}
