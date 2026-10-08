import Testing

@testable import CmdBabyKit

private let oneScreen = [
  TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
]

@Test("La planète est plus lente et plus grande que les astéroïdes, et son sprite est une planète")
func planetsAreSlowerAndLargerThanAsteroids() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()

  let launched = scenery.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rng)
  let planet = launched.first { $0.layer == .planet }
  let far = launched.first { $0.layer == .farAsteroid }
  let near = launched.first { $0.layer == .nearAsteroid }

  #expect(planet != nil)
  #expect(far != nil)
  #expect(near != nil)
  guard let planet, let far, let near else { return }

  #expect(planet.size > near.size)
  #expect(planet.size > far.size)
  #expect(planet.size >= 0.30 * 600)
  #expect(planet.size <= 0.60 * 600)
  #expect(speed(of: planet) < speed(of: far))
  #expect(speed(of: planet) < speed(of: near))
  #expect(planet.opacity < 1)
  #expect(StarshipCatalog.planets.contains(planet.sprite))
  #expect(planet.startY > 600)
  #expect(planet.endY < 0)
  #expect(planet.duration >= 40)
  #expect(planet.duration <= 90)
}

@Test("Sur un écran de 1 440 pt de haut, une planète traverse en 40 à 90 s, plus longtemps que les astéroïdes")
func planetCrossesATallScreenWithinFortyToNinetySeconds() {
  let height = 1_440.0
  let screen = [TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: height)]

  // 30 % : 432 pt, départ 1 656, arrivée −216. 60 % : 864 pt, départ 1 872, arrivée −432.
  let cases: [(fraction: Double, size: Double, startY: Double, endY: Double)] = [
    (0.30, 432, 1_656, -216),
    (0.60, 864, 1_872, -432),
  ]
  for specimen in cases {
    var rng = SplitMix64(seed: 1)
    var scenery = StarshipScenery()
    var tuning = StarshipTuning.standard
    tuning.planetScenery.sizeFractionOfTallestScreen = specimen.fraction...specimen.fraction

    let launched = scenery.launch(screens: screen, now: 0, tuning: tuning, rng: &rng)
    let planet = launched.first { $0.layer == .planet }
    let far = launched.first { $0.layer == .farAsteroid }
    let near = launched.first { $0.layer == .nearAsteroid }
    #expect(planet != nil)
    #expect(far != nil)
    #expect(near != nil)
    guard let planet, let far, let near else { continue }

    #expect(abs(planet.size - specimen.size) < 1e-6)
    #expect(abs(planet.startY - specimen.startY) < 1e-6)
    #expect(abs(planet.endY - specimen.endY) < 1e-6)
    #expect(planet.duration >= 40)
    #expect(planet.duration <= 90)
    #expect(planet.duration > far.duration)
    #expect(planet.duration > near.duration)
    #expect(abs(far.duration - 74.8) < 1e-6)
    #expect(abs(near.duration - 38.4) < 1e-6)
  }
}

@Test("Un astéroïde part au-dessus de l’union et arrive en dessous")
func sceneryCrossesFromAboveTheUnionToBelow() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()

  let launched = scenery.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rng)

  #expect(!launched.isEmpty)
  #expect(launched.allSatisfy { $0.startY > 600 })
  #expect(launched.allSatisfy { $0.endY < 0 })
  #expect(launched.allSatisfy { $0.x >= 0 && $0.x <= 800 })
}

@Test("L’astéroïde proche est plus rapide et plus grand que le lointain, et les deux sont des météores assombris")
func nearAsteroidsAreFasterAndLargerThanFarOnes() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()
  let launched = scenery.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rng)
  let far = launched.first { $0.layer == .farAsteroid }
  let near = launched.first { $0.layer == .nearAsteroid }
  let sprites = Set(StarshipCatalog.sprites(for: .meteor))

  #expect(far != nil)
  #expect(near != nil)
  guard let far, let near else { return }
  #expect(near.size > far.size)
  #expect(speed(of: near) > speed(of: far))
  #expect(far.opacity < near.opacity)
  #expect(near.opacity < 1)
  #expect(sprites.contains(far.sprite))
  #expect(sprites.contains(near.sprite))
  #expect(Set(launched.map(\.layer)) == [.planet, .farAsteroid, .nearAsteroid])
}

@Test("Un écran de 800×600 lance un lointain de 40 pt qui met 12,8 s et passe par y = 300")
func farAsteroidFollowsAWorkedCrossing() {
  var rng = SplitMix64(seed: 7)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 100
  tuning.farAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 2, size: 40, opacity: 0.4, ceiling: 1, meanInterval: 100
  )
  tuning.nearAsteroidScenery.ceiling = 0
  tuning.planetScenery.ceiling = 0

  let launched = scenery.launch(screens: oneScreen, now: 0, tuning: tuning, rng: &rng)
  #expect(launched.count == 1)
  guard let element = launched.first else { return }

  #expect(element.layer == .farAsteroid)
  #expect(abs(element.startY - 620) < 1e-6)
  #expect(abs(element.endY - (-20)) < 1e-6)
  #expect(abs(element.duration - 12.8) < 1e-6)
  #expect(abs(element.ordinate(at: 0) - 620) < 1e-6)
  #expect(abs(element.ordinate(at: 6.4) - 300) < 1e-6)
  #expect(scenery.flying(at: 0).map(\.id) == [element.id])
  #expect(scenery.flying(at: 6.4).map(\.id) == [element.id])
  #expect(scenery.flying(at: 12.8).isEmpty)
}

@Test("Deux écrans côte à côte voient le même astéroïde à la même hauteur")
func sideBySideScreensShareTheVerticalPosition() {
  let left = TerminalScreen(index: 0, x: 0, y: 100, width: 800, height: 600)
  let right = TerminalScreen(index: 1, x: 800, y: 100, width: 800, height: 400)
  var rng = SplitMix64(seed: 3)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 100
  tuning.farAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 2, size: 40, opacity: 0.4, ceiling: 1, meanInterval: 100
  )
  tuning.nearAsteroidScenery.ceiling = 0
  tuning.planetScenery.ceiling = 0

  let launched = scenery.launch(screens: [left, right], now: 0, tuning: tuning, rng: &rng)
  guard let element = launched.first else {
    #expect(Bool(false))
    return
  }

  let onLeft = element.localPoint(at: 0, on: left)
  let onRight = element.localPoint(at: 0, on: right)
  #expect(abs(element.startY - 720) < 1e-6)
  #expect(abs(element.endY - 80) < 1e-6)
  #expect(abs(onLeft.y - 620) < 1e-6)
  #expect(abs(onRight.y - 620) < 1e-6)
  #expect(abs((onLeft.x - onRight.x) - 800) < 1e-6)
  #expect(element.x >= 0)
  #expect(element.x <= 1600)
}

@Test("Le plafond des planètes tient : jamais plus de deux en vol, et d’autres partent ensuite")
func planetCeilingHoldsAtEveryInstant() {
  var rng = SplitMix64(seed: 11)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 4_000
  tuning.planetScenery.depth = 1
  tuning.planetScenery.ceiling = 2
  tuning.planetScenery.meanInterval = 0.2
  tuning.planetScenery.sizeFractionOfTallestScreen = 0.20...0.20
  tuning.farAsteroidScenery.ceiling = 0
  tuning.nearAsteroidScenery.ceiling = 0
  let screen = [TerminalScreen(index: 0, x: 0, y: 0, width: 200, height: 100)]

  var launchedCount = 0
  var now = 0.0
  var steps = 0
  while now <= 3 {
    let launched = scenery.launch(screens: screen, now: now, tuning: tuning, rng: &rng)
    launchedCount += launched.filter { $0.layer == .planet }.count
    #expect(scenery.flying(at: now).filter { $0.layer == .planet }.count <= 2)
    steps += 1
    now += 0.01
  }

  #expect(steps == 301)
  #expect(launchedCount > 2)
}

@Test("Une planète mesure la moitié de l’écran le plus haut, pas celle de l’union empilée, et met 70 s")
func planetSizeFollowsTheTallestScreen() {
  let low = TerminalScreen(index: 0, x: 0, y: 0, width: 500, height: 400)
  let high = TerminalScreen(index: 1, x: 0, y: 1000, width: 500, height: 200)
  var rng = SplitMix64(seed: 2)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 100
  tuning.planetScenery = StarshipSceneryLayerTuning(
    depth: 5,
    size: 0,
    opacity: 0.7,
    ceiling: 1,
    meanInterval: 100,
    sizeFractionOfTallestScreen: 0.50...0.50
  )
  tuning.farAsteroidScenery.ceiling = 0
  tuning.nearAsteroidScenery.ceiling = 0

  let launched = scenery.launch(screens: [low, high], now: 0, tuning: tuning, rng: &rng)
  #expect(launched.count == 1)
  guard let planet = launched.first else { return }

  #expect(planet.layer == .planet)
  #expect(abs(planet.size - 200) < 1e-6)
  #expect(abs(planet.startY - 1300) < 1e-6)
  #expect(abs(planet.endY - (-100)) < 1e-6)
  #expect(abs(planet.duration - 70) < 1e-6)
  #expect(planet.x >= 0)
  #expect(planet.x <= 500)
}

@Test("L’abscisse d’une planète peut chevaucher deux écrans côte à côte")
func planetAbscissaCanStraddleTwoScreens() {
  let left = TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
  let right = TerminalScreen(index: 1, x: 800, y: 0, width: 800, height: 600)
  var rng = SplitMix64(seed: 3)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 10_000
  tuning.planetScenery.depth = 1
  tuning.planetScenery.ceiling = 1
  tuning.planetScenery.meanInterval = 1
  tuning.planetScenery.sizeFractionOfTallestScreen = 0.50...0.50
  tuning.farAsteroidScenery.ceiling = 0
  tuning.nearAsteroidScenery.ceiling = 0

  var sawLeft = false
  var sawRight = false
  var straddles = false
  var now = 0.0
  for _ in 0..<40 {
    let launched = scenery.launch(screens: [left, right], now: now, tuning: tuning, rng: &rng)
    guard let planet = launched.first(where: { $0.layer == .planet }) else {
      #expect(Bool(false))
      return
    }
    #expect(abs(planet.size - 300) < 1e-6)
    #expect(planet.x >= 0)
    #expect(planet.x <= 1600)
    if planet.x < 800 { sawLeft = true }
    if planet.x > 800 { sawRight = true }
    if planet.x - 150 < 800, planet.x + 150 > 800 { straddles = true }
    now += 5
  }

  #expect(sawLeft)
  #expect(sawRight)
  #expect(straddles)
}

@Test("reset oublie la planète précédente : le même germe rejoue la même apparition")
func resetForgetsThePreviousPlanet() {
  var tuning = StarshipTuning()
  tuning.farAsteroidScenery.ceiling = 0
  tuning.nearAsteroidScenery.ceiling = 0

  var rng = SplitMix64(seed: 4)
  var scenery = StarshipScenery()
  _ = scenery.launch(screens: oneScreen, now: 0, tuning: tuning, rng: &rng)
  scenery.reset()

  var replayed = SplitMix64(seed: 4)
  let afterReset = scenery.launch(screens: oneScreen, now: 0, tuning: tuning, rng: &replayed)
  var freshRng = SplitMix64(seed: 4)
  var fresh = StarshipScenery()
  let fromScratch = fresh.launch(screens: oneScreen, now: 0, tuning: tuning, rng: &freshRng)

  #expect(afterReset == fromScratch)
}

@Test("En cinq minutes, plusieurs planètes passent et jamais plus de deux à la fois")
func fiveMinutesShowsSeveralPlanets() {
  var rng = SplitMix64(seed: 8)
  var scenery = StarshipScenery()
  let screen = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]

  var launched = 0
  var now = 0.0
  while now <= 300 {
    let fresh = scenery.launch(screens: screen, now: now, tuning: .standard, rng: &rng)
    launched += fresh.filter { $0.layer == .planet }.count
    #expect(scenery.flying(at: now).filter { $0.layer == .planet }.count <= 2)
    now += 0.5
  }

  #expect(launched >= 3)
}

@Test("Deux planètes successives ne sont jamais la même")
func successivePlanetsDiffer() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 10_000
  tuning.planetScenery.depth = 1
  tuning.planetScenery.ceiling = 1
  tuning.planetScenery.meanInterval = 1
  tuning.planetScenery.sizeFractionOfTallestScreen = 0.30...0.30
  tuning.farAsteroidScenery.ceiling = 0
  tuning.nearAsteroidScenery.ceiling = 0

  var previous: String?
  var count = 0
  var now = 0.0
  for _ in 0..<12 {
    let launched = scenery.launch(screens: oneScreen, now: now, tuning: tuning, rng: &rng)
    let planets = launched.filter { $0.layer == .planet }
    #expect(planets.count == 1)
    guard let planet = planets.first else { return }
    if let previous {
      #expect(planet.sprite != previous)
    }
    previous = planet.sprite
    count += 1
    now += 10
  }

  #expect(count == 12)
}

@Test("Le plafond d’une couche tient à chaque instant, même quand l’intervalle est court")
func layerCeilingHoldsAtEveryInstant() {
  var rng = SplitMix64(seed: 11)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.sceneryReferenceSpeed = 400
  tuning.farAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 1, size: 20, opacity: 0.3, ceiling: 1, meanInterval: 0.2
  )
  tuning.nearAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 1, size: 20, opacity: 0.6, ceiling: 2, meanInterval: 0.2
  )
  let screen = [TerminalScreen(index: 0, x: 0, y: 0, width: 200, height: 100)]

  var farLaunched = 0
  var nearLaunched = 0
  var steps = 0
  var now = 0.0
  while now <= 3 {
    let launched = scenery.launch(screens: screen, now: now, tuning: tuning, rng: &rng)
    farLaunched += launched.filter { $0.layer == .farAsteroid }.count
    nearLaunched += launched.filter { $0.layer == .nearAsteroid }.count
    let flying = scenery.flying(at: now)
    #expect(flying.filter { $0.layer == .farAsteroid }.count <= 1)
    #expect(flying.filter { $0.layer == .nearAsteroid }.count <= 2)
    steps += 1
    now += 0.01
  }

  #expect(steps == 301)
  #expect(farLaunched > 1)
  #expect(nearLaunched > 2)
}

@Test("L’intervalle moyen espace les apparitions : rien avant la moitié, une avant une fois et demie")
func meanIntervalSpacesAppearances() {
  var rng = SplitMix64(seed: 5)
  var scenery = StarshipScenery()
  var tuning = StarshipTuning()
  tuning.farAsteroidScenery.meanInterval = 10
  tuning.farAsteroidScenery.ceiling = 5
  tuning.nearAsteroidScenery.ceiling = 0

  let first = scenery.launch(screens: oneScreen, now: 0, tuning: tuning, rng: &rng)
  #expect(first.filter { $0.layer == .farAsteroid }.count == 1)
  let early = scenery.launch(screens: oneScreen, now: 4, tuning: tuning, rng: &rng)
  #expect(early.filter { $0.layer == .farAsteroid }.isEmpty)
  let later = scenery.launch(screens: oneScreen, now: 15, tuning: tuning, rng: &rng)
  #expect(later.filter { $0.layer == .farAsteroid }.count == 1)
}

@Test("Les éléments en vol à t sont ceux émis dont la traversée contient t")
func flyingStateMatchesLaunchedElements() {
  var rng = SplitMix64(seed: 9)
  var scenery = StarshipScenery()
  let launched = scenery.launch(screens: oneScreen, now: 10, tuning: .standard, rng: &rng)

  #expect(launched.count == 3)
  for element in launched {
    #expect(scenery.flying(at: element.start).contains(element))
    #expect(scenery.flying(at: element.start + element.duration / 2).contains(element))
    #expect(scenery.flying(at: element.start + element.duration).contains(element) == false)
  }
}

@Test("reset vide le décor, qui peut repartir")
func resetClearsScenery() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()
  let launched = scenery.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rng)
  #expect(!launched.isEmpty)
  #expect(!scenery.flying(at: 0).isEmpty)

  scenery.reset()

  #expect(scenery.flying(at: 0).isEmpty)
  let again = scenery.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rng)
  #expect(again.count == launched.count)
  #expect(again.map(\.id) == launched.map(\.id))
}

@Test("Sans écran, ou avec une union vide, rien ne part")
func emptyUnionLaunchesNothing() {
  var rng = SplitMix64(seed: 1)
  var scenery = StarshipScenery()
  let flat = [TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 0)]

  #expect(scenery.launch(screens: [], now: 0, tuning: .standard, rng: &rng).isEmpty)
  #expect(scenery.launch(screens: flat, now: 0, tuning: .standard, rng: &rng).isEmpty)
  #expect(scenery.flying(at: 0).isEmpty)
}

@Test("La même graine reproduit les mêmes apparitions")
func sameSeedReplaysTheSameAppearances() {
  var rngA = SplitMix64(seed: 42)
  var rngB = SplitMix64(seed: 42)
  var a = StarshipScenery()
  var b = StarshipScenery()

  let firstA = a.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rngA)
  let firstB = b.launch(screens: oneScreen, now: 0, tuning: .standard, rng: &rngB)
  let laterA = a.launch(screens: oneScreen, now: 30, tuning: .standard, rng: &rngA)
  let laterB = b.launch(screens: oneScreen, now: 30, tuning: .standard, rng: &rngB)

  #expect(firstA == firstB)
  #expect(laterA == laterB)
  #expect(a == b)
}

private func speed(of element: StarshipSceneryElement) -> Double {
  (element.startY - element.endY) / element.duration
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
