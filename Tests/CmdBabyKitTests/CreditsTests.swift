import Foundation
import Testing

@testable import CmdBabyKit

@Test("L’auteur est Camille, vers https://camillehdl.dev")
func creditsAuthorPointsAtCamilleSite() {
  #expect(Credits.authorName == "Camille")
  #expect(Credits.authorURL.absoluteString == "https://camillehdl.dev")
}

@Test("Cinq packs Kenney, licence CC0, chacun une URL https")
func creditsListsKenneyPacksInOrder() {
  #expect(Credits.assets.map(\.name) == [
    "Fish Pack 2.0",
    "Space Shooter Remastered",
    "Alien UFO Pack",
    "Skyboxes Space",
    "Planets",
  ])
  #expect(Credits.assets.map(\.author) == ["Kenney", "Kenney", "Kenney", "Kenney", "Kenney"])
  #expect(Credits.assets.map(\.license) == ["CC0", "CC0", "CC0", "CC0", "CC0"])
  #expect(Credits.assets.map(\.url.absoluteString) == [
    "https://kenney.nl/assets/fish-pack",
    "https://kenney.nl/assets/space-shooter-remastered",
    "https://kenney.nl/assets/alien-ufo-pack",
    "https://kenney.nl/assets/skyboxes-space",
    "https://kenney.nl/assets/planets",
  ])
  #expect(Credits.assets.allSatisfy { $0.url.scheme == "https" })
}

@Test("Confidentialité et Support pointent vers le site, dans la langue de l’app, en https")
func creditsLinkToPrivacyAndSupportPages() {
  #expect(Credits.privacyURL(.language("en")).absoluteString == "https://cmdbaby.app/privacy/")
  #expect(Credits.supportURL(.language("en")).absoluteString == "https://cmdbaby.app/support/")
  #expect(Credits.privacyURL(.language("fr")).absoluteString == "https://cmdbaby.app/fr/privacy/")
  #expect(Credits.supportURL(.language("fr")).absoluteString == "https://cmdbaby.app/fr/support/")
  #expect(L10nTable.language("fr")("settings.about.privacy") == "Confidentialité")
  #expect(L10nTable.language("en")("settings.about.privacy") == "Privacy")
  #expect(L10nTable.language("fr")("settings.about.support") == "Support")
}
