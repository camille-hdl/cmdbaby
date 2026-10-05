import Foundation

/// Tirage de la skybox de départ d’une session.
public enum StarshipSkyboxRotation: Sendable {
  /// Skybox de départ, tirée uniformément dans `StarshipCatalog.skyboxes`.
  public static func first(using rng: inout some RandomNumberGenerator) -> String {
    let names = StarshipCatalog.skyboxes
    let index = Int.random(in: 0..<names.count, using: &rng)
    return names[index]
  }
}
