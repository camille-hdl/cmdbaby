import Foundation

public enum StarshipTargetKind: CaseIterable, Equatable, Sendable {
  case meteor, alien, enemy
}

/// Noms d’images Kenney du mode Vaisseau, sans extension.
public enum StarshipCatalog: Sendable {
  public static let shipSprite = "playerShip1_blue"
  public static let beamSprite = "laserBlue01"
  public static let explosionSprite = "laserBlue_burst"
  public static let previewSkybox = "starship_preview_skybox"

  public static let debrisSprites = [
    "meteorBrown_tiny1",
    "meteorBrown_tiny2",
    "meteorGrey_tiny1",
    "meteorGrey_tiny2",
    "star1",
    "star2",
    "star3",
  ]

  public static let skyboxes = [
    "skybox-space-band",
    "skybox-space-dark",
    "skybox-space-day",
    "skybox-space-galaxy",
    "skybox-space-nebula",
  ]

  public static func sprites(for kind: StarshipTargetKind) -> [String] {
    switch kind {
    case .meteor:
      numbered("meteorBrown_big", 1...4) + numbered("meteorGrey_big", 1...4)
    case .alien:
      [
        "ufoBlue",
        "ufoGreen",
        "ufoRed",
        "ufoYellow",
        "shipBeige_manned",
        "shipBlue_manned",
        "shipGreen_manned",
        "shipPink_manned",
        "shipYellow_manned",
      ]
    case .enemy:
      ["Black", "Blue", "Green", "Red"].flatMap { color in
        numbered("enemy\(color)", 1...5)
      }
    }
  }

  /// Tous les noms d’images du mode, pour vérifier au chargement qu’aucun ne manque.
  public static var allImageNames: [String] {
    [shipSprite, beamSprite, explosionSprite]
      + debrisSprites
      + sprites(for: .meteor)
      + sprites(for: .alien)
      + sprites(for: .enemy)
      + skyboxes
      + [previewSkybox]
  }

  private static func numbered(_ prefix: String, _ range: ClosedRange<Int>) -> [String] {
    range.map { "\(prefix)\($0)" }
  }
}
