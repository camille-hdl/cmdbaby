import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Chaque sorte de cible a au moins un sprite, aux effectifs Kenney")
func starshipCatalogTargetSpriteCounts() {
  #expect(!StarshipCatalog.sprites(for: .meteor).isEmpty)
  #expect(!StarshipCatalog.sprites(for: .alien).isEmpty)
  #expect(!StarshipCatalog.sprites(for: .enemy).isEmpty)
  #expect(StarshipCatalog.sprites(for: .meteor).count == 8)
  #expect(StarshipCatalog.sprites(for: .alien).count == 9)
  #expect(StarshipCatalog.sprites(for: .enemy).count == 20)
  #expect(StarshipCatalog.sprites(for: .meteor) == [
    "meteorBrown_big1",
    "meteorBrown_big2",
    "meteorBrown_big3",
    "meteorBrown_big4",
    "meteorGrey_big1",
    "meteorGrey_big2",
    "meteorGrey_big3",
    "meteorGrey_big4",
  ])
  #expect(StarshipCatalog.sprites(for: .alien) == [
    "ufoBlue",
    "ufoGreen",
    "ufoRed",
    "ufoYellow",
    "shipBeige_manned",
    "shipBlue_manned",
    "shipGreen_manned",
    "shipPink_manned",
    "shipYellow_manned",
  ])
  #expect(StarshipCatalog.sprites(for: .enemy) == [
    "enemyBlack1", "enemyBlack2", "enemyBlack3", "enemyBlack4", "enemyBlack5",
    "enemyBlue1", "enemyBlue2", "enemyBlue3", "enemyBlue4", "enemyBlue5",
    "enemyGreen1", "enemyGreen2", "enemyGreen3", "enemyGreen4", "enemyGreen5",
    "enemyRed1", "enemyRed2", "enemyRed3", "enemyRed4", "enemyRed5",
  ])
}

@Test("Les cinq skyboxes sont listées par ordre alphabétique")
func starshipCatalogListsSkyboxesAlphabetically() {
  #expect(StarshipCatalog.skyboxes.count == 5)
  #expect(StarshipCatalog.skyboxes == [
    "skybox-space-band",
    "skybox-space-dark",
    "skybox-space-day",
    "skybox-space-galaxy",
    "skybox-space-nebula",
  ])
}

@Test("Le catalogue nomme les 53 images du mode, sans doublon")
func starshipCatalogNamesEveryImageOnce() {
  #expect(StarshipCatalog.shipSprite == "playerShip1_blue")
  #expect(StarshipCatalog.beamSprite == "laserBlue01")
  #expect(StarshipCatalog.explosionSprite == "laserBlue_burst")
  #expect(StarshipCatalog.previewSkybox == "starship_preview_skybox")
  #expect(StarshipCatalog.debrisSprites == [
    "meteorBrown_tiny1",
    "meteorBrown_tiny2",
    "meteorGrey_tiny1",
    "meteorGrey_tiny2",
    "star1",
    "star2",
    "star3",
  ])

  let names = StarshipCatalog.allImageNames
  let expected = [
    "playerShip1_blue",
    "laserBlue01",
    "laserBlue_burst",
    "meteorBrown_tiny1",
    "meteorBrown_tiny2",
    "meteorGrey_tiny1",
    "meteorGrey_tiny2",
    "star1",
    "star2",
    "star3",
    "meteorBrown_big1",
    "meteorBrown_big2",
    "meteorBrown_big3",
    "meteorBrown_big4",
    "meteorGrey_big1",
    "meteorGrey_big2",
    "meteorGrey_big3",
    "meteorGrey_big4",
    "ufoBlue",
    "ufoGreen",
    "ufoRed",
    "ufoYellow",
    "shipBeige_manned",
    "shipBlue_manned",
    "shipGreen_manned",
    "shipPink_manned",
    "shipYellow_manned",
    "enemyBlack1", "enemyBlack2", "enemyBlack3", "enemyBlack4", "enemyBlack5",
    "enemyBlue1", "enemyBlue2", "enemyBlue3", "enemyBlue4", "enemyBlue5",
    "enemyGreen1", "enemyGreen2", "enemyGreen3", "enemyGreen4", "enemyGreen5",
    "enemyRed1", "enemyRed2", "enemyRed3", "enemyRed4", "enemyRed5",
    "skybox-space-band",
    "skybox-space-dark",
    "skybox-space-day",
    "skybox-space-galaxy",
    "skybox-space-nebula",
    "starship_preview_skybox",
  ]
  #expect(expected.count == 53)
  #expect(names.count == 53)
  #expect(Set(names).count == names.count)
  #expect(Set(names) == Set(expected))
}
