import Foundation

/// Tirage de la skybox de départ, puis des suivantes.
public enum StarshipSkyboxRotation: Sendable {
  /// Skybox de départ, tirée uniformément dans `StarshipCatalog.skyboxes`.
  public static func first(using rng: inout some RandomNumberGenerator) -> String {
    let names = StarshipCatalog.skyboxes
    let index = Int.random(in: 0..<names.count, using: &rng)
    return names[index]
  }

  /// Skybox suivante : tirée uniformément parmi `StarshipCatalog.skyboxes` sauf `current`.
  /// Si `current` n’est pas dans le catalogue, tirage parmi toutes.
  public static func next(after current: String, using rng: inout some RandomNumberGenerator) -> String {
    let pool = StarshipCatalog.skyboxes.filter { $0 != current }
    return pool.randomElement(using: &rng) ?? current
  }
}
