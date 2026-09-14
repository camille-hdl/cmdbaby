import CoreGraphics
import Testing

@testable import BabyWorkDiagnosticsKit

private let screen = CGSize(width: 800, height: 600)
private let groundTop = 0.22 * 600
private let displaySizeRange: ClosedRange<Double> = 96...150

@Test("Un spawn place le poisson dans la moitié gauche, au-dessus du sol")
func spawnPlacesFishInLeftWaterColumn() {
  var rng = SplitMix64(seed: 1)
  var school = OceanSchool()

  let first = spawn(&school, rng: &rng)
  #expect(first.id == 1)
  #expect(first.x >= OceanSchool.padding)
  #expect(first.x <= screen.width / 2)
  #expect(first.y > groundTop)
  #expect(first.speed >= OceanSchool.swimMin)
  #expect(first.speed <= OceanSchool.swimMax)
  #expect(OceanFishKind.allCases.contains(first.kind))
  #expect(displaySizeRange.contains(first.displaySize))

  let second = spawn(&school, rng: &rng)
  #expect(second.id == 2)
  #expect(school.count == 2)
}

@Test("Le tick avance x sans changer y")
func tickAdvancesX() {
  let fish = OceanFish(
    id: 1,
    x: 100,
    y: 300,
    speed: 40,
    kind: .blue,
    displaySize: 100,
    screenIndex: 0
  )
  var school = OceanSchool(fish: [fish])

  let tick = school.tick(dt: 1, screenWidths: [800])

  #expect(tick.fish.count == 1)
  #expect(tick.fish[0].x == 140)
  #expect(tick.fish[0].y == 300)
  #expect(tick.removedIDs.isEmpty)
  #expect(tick.fish == school.fish)
}

@Test("Un poisson hors écran à droite est retiré")
func tickCullsFishPastRightEdge() {
  let displaySize = 100.0
  let fish = OceanFish(
    id: 7,
    x: 800 + displaySize,
    y: 300,
    speed: 40,
    kind: .green,
    displaySize: displaySize,
    screenIndex: 0
  )
  var school = OceanSchool(fish: [fish])

  let tick = school.tick(dt: 1, screenWidths: [800])

  #expect(school.count == 0)
  #expect(tick.fish.isEmpty)
  #expect(tick.removedIDs == [7])
}

@Test("Cent poissons nagent encore à leur vitesse de nage")
func oneHundredFishStayAtSwimSpeed() {
  var rng = SplitMix64(seed: 1)
  var school = OceanSchool()
  spawnMany(OceanSchool.maxFish, into: &school, rng: &rng)

  #expect(school.count == 100)
  #expect(school.fish.allSatisfy { $0.speed < OceanSchool.exitSpeed })
  #expect(school.fish.allSatisfy { (OceanSchool.swimMin...OceanSchool.swimMax).contains($0.speed) })
}

@Test("Le 101ᵉ spawn accélère le plus vieux et laisse nager le nouveau-né")
func oneHundredAndFirstSpawnBoostsOldest() {
  var rng = SplitMix64(seed: 1)
  var school = OceanSchool()
  spawnMany(OceanSchool.maxFish, into: &school, rng: &rng)

  let newborn = spawn(&school, rng: &rng)

  #expect(school.count == 101)
  let oldest = school.fish.first { $0.id == 1 }
  #expect(oldest?.speed == OceanSchool.exitSpeed)
  #expect((OceanSchool.swimMin...OceanSchool.swimMax).contains(newborn.speed))
}

@Test("Après le cull du trop-plein, les poissons déjà boostés restent à exitSpeed")
func boostedFishStayBoostedAfterCull() {
  var rng = SplitMix64(seed: 1)
  var school = OceanSchool()
  spawnMany(OceanSchool.maxFish + 2, into: &school, rng: &rng)

  #expect(school.fish.first { $0.id == 1 }?.speed == OceanSchool.exitSpeed)
  #expect(school.fish.first { $0.id == 2 }?.speed == OceanSchool.exitSpeed)

  var fish = school.fish
  for index in fish.indices where fish[index].id >= 101 {
    fish[index].x = 800 + fish[index].displaySize
  }
  school = OceanSchool(fish: fish)

  let tick = school.tick(dt: 0, screenWidths: [800])

  #expect(school.count == 100)
  #expect(tick.fish.count == 100)
  let remainingBoosted = tick.fish.filter { $0.id == 1 || $0.id == 2 }
  #expect(remainingBoosted.count == 2)
  #expect(remainingBoosted.allSatisfy { $0.speed == OceanSchool.exitSpeed })
}

@Test("La même séquence et la même graine reproduisent le banc")
func sameSeedReplaysTheSameSchool() {
  var rngA = SplitMix64(seed: 42)
  var rngB = SplitMix64(seed: 42)
  var schoolA = OceanSchool()
  var schoolB = OceanSchool()

  spawnMany(8, into: &schoolA, rng: &rngA)
  spawnMany(8, into: &schoolB, rng: &rngB)

  #expect(schoolA.fish.map(\.kind) == schoolB.fish.map(\.kind))
  #expect(schoolA.fish.map(\.x) == schoolB.fish.map(\.x))
  #expect(schoolA.fish.map(\.y) == schoolB.fish.map(\.y))
  #expect(schoolA.fish.map(\.speed) == schoolB.fish.map(\.speed))
  #expect(schoolA.fish.map(\.displaySize) == schoolB.fish.map(\.displaySize))
}

@Test("Un écran minuscule spawn au centre")
func invalidWaterColumnSpawnsAtCenter() {
  var rng = SplitMix64(seed: 1)
  var school = OceanSchool()
  let tiny = CGSize(width: 100, height: 100)
  let spawned = school.spawnFish(
    screenIndex: 0,
    screenSize: tiny,
    groundTop: 80,
    displaySizeRange: displaySizeRange,
    rng: &rng
  )

  #expect(spawned.x == Double(tiny.width) / 4)
  #expect(spawned.y == Double(tiny.height) / 2)
}

@Test("Un indice d’écran hors bornes cull immédiatement")
func outOfBoundsScreenIndexIsCulled() {
  let fish = OceanFish(
    id: 1,
    x: 100,
    y: 300,
    speed: 40,
    kind: .blue,
    displaySize: 100,
    screenIndex: 3
  )
  var school = OceanSchool(fish: [fish])

  let tick = school.tick(dt: 1, screenWidths: [800])

  #expect(school.count == 0)
  #expect(tick.removedIDs == [1])
}

private func spawn(_ school: inout OceanSchool, rng: inout SplitMix64) -> OceanFish {
  school.spawnFish(
    screenIndex: 0,
    screenSize: screen,
    groundTop: groundTop,
    displaySizeRange: displaySizeRange,
    rng: &rng
  )
}

private func spawnMany(_ count: Int, into school: inout OceanSchool, rng: inout SplitMix64) {
  for _ in 0..<count {
    _ = spawn(&school, rng: &rng)
  }
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
