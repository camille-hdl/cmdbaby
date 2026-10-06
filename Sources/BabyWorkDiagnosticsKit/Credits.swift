import Foundation

/// Un pack d’images crédité dans la section À propos. Le nom n’est pas traduit.
public struct CreditedAsset: Equatable, Sendable {
  public let name: String
  public let author: String
  public let license: String
  public let url: URL
}

/// Auteur de CmdBaby et packs d’images affichés dans les Réglages.
public enum Credits {
  public static let authorName = "Camille"
  public static let authorURL = URL(string: "https://camillehdl.dev")!

  /// Fish Pack, puis le vaisseau : Space Shooter, Alien UFO, Skyboxes.
  public static let assets: [CreditedAsset] = [
    asset("Fish Pack 2.0", "https://kenney.nl/assets/fish-pack"),
    asset("Space Shooter Remastered", "https://kenney.nl/assets/space-shooter-remastered"),
    asset("Alien UFO Pack", "https://kenney.nl/assets/alien-ufo-pack"),
    asset("Skyboxes Space", "https://kenney.nl/assets/skyboxes-space"),
  ]

  private static func asset(_ name: String, _ url: String) -> CreditedAsset {
    CreditedAsset(
      name: name,
      author: "Kenney",
      license: "CC0",
      url: URL(string: url)!
    )
  }
}
