import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le premier tirage reste dans le catalogue, et 200 tirages couvrent les cinq ciels")
func skyboxRotationFirstDrawStaysInTheCatalog() {
  var rng = SplitMix64(seed: 1)
  var seen: Set<String> = []
  for _ in 0..<200 {
    let name = StarshipSkyboxRotation.first(using: &rng)
    #expect(StarshipCatalog.skyboxes.contains(name))
    seen.insert(name)
  }
  #expect(seen.count == StarshipCatalog.skyboxes.count)
}

@Test("La skybox suivante n’est jamais celle affichée et reste dans le catalogue")
func skyboxRotationNextSkipsTheCurrentSky() {
  for current in StarshipCatalog.skyboxes {
    var rng = SplitMix64(seed: 1)
    for _ in 0..<100 {
      let name = StarshipSkyboxRotation.next(after: current, using: &rng)
      #expect(name != current)
      #expect(StarshipCatalog.skyboxes.contains(name))
    }
  }
}

@Test("Quatre cents tirages après skybox-space-band couvrent les quatre autres ciels")
func skyboxRotationNextCoversTheOtherSkies() {
  var rng = SplitMix64(seed: 1)
  var seen: Set<String> = []
  for _ in 0..<400 {
    seen.insert(StarshipSkyboxRotation.next(after: "skybox-space-band", using: &rng))
  }
  #expect(seen == [
    "skybox-space-dark",
    "skybox-space-day",
    "skybox-space-galaxy",
    "skybox-space-nebula",
  ])
}

@Test("Une skybox inconnue laisse place à un ciel du catalogue")
func skyboxRotationNextDrawsFromTheCatalogWhenCurrentIsUnknown() {
  var rng = SplitMix64(seed: 1)
  let name = StarshipSkyboxRotation.next(after: "inconnu", using: &rng)
  #expect(StarshipCatalog.skyboxes.contains(name))
}

private struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}
