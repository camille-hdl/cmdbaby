import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("L’auteur est Camille, vers https://camillehdl.dev")
func creditsAuthorPointsAtCamilleSite() {
  #expect(Credits.authorName == "Camille")
  #expect(Credits.authorURL.absoluteString == "https://camillehdl.dev")
}

@Test("Quatre packs Kenney, licence CC0, chacun une URL https")
func creditsListsKenneyPacksInOrder() {
  #expect(Credits.assets.map(\.name) == [
    "Fish Pack 2.0",
    "Space Shooter Remastered",
    "Alien UFO Pack",
    "Skyboxes Space",
  ])
  #expect(Credits.assets.map(\.author) == ["Kenney", "Kenney", "Kenney", "Kenney"])
  #expect(Credits.assets.map(\.license) == ["CC0", "CC0", "CC0", "CC0"])
  #expect(Credits.assets.map(\.url.absoluteString) == [
    "https://kenney.nl/assets/fish-pack",
    "https://kenney.nl/assets/space-shooter-remastered",
    "https://kenney.nl/assets/alien-ufo-pack",
    "https://kenney.nl/assets/skyboxes-space",
  ])
  #expect(Credits.assets.allSatisfy { $0.url.scheme == "https" })
}
