import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Un seul écran est choisi")
func largestScreenIndexSelectsTheOnlyScreen() {
  let screens = [
    TerminalScreen(index: 2, x: 0, y: 0, width: 1440, height: 900)
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 2)
}

@Test("Le plus grand écran l’emporte")
func largestScreenIndexPrefersGreaterArea() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 2560, height: 1440),
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 1)
}

@Test("À surface égale, le plus petit index l’emporte")
func largestScreenIndexTieBreaksToSmallerIndex() {
  let screens = [
    TerminalScreen(index: 3, x: 0, y: 0, width: 200, height: 100),
    TerminalScreen(index: 1, x: 200, y: 0, width: 100, height: 200),
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 1)
}

@Test("Une liste vide ne désigne aucun écran")
func largestScreenIndexOfEmptyListIsNil() {
  let screens: [TerminalScreen] = []
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == nil)
}

@Test("Le centre de la cellule, pas le clic brut, décide si la colonne coule")
func cellCenterDecidesWhetherAClickColumnFlows() {
  let offset = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 1500, y: 1080, width: 1440, height: 900),
  ])
  let onTheEdge = 1920.0
  let columnX = TerminalStyle.snapToGrid(x: onTheEdge)
  let centerX = columnX + TerminalStyle.cellWidth / 2
  #expect(columnX == 1904)
  #expect(offset.highestScreen(atX: centerX)?.index == 1)
  #expect(offset.fallFloor(atX: centerX, fromTopY: 1980) == 0)
  #expect(offset.fallFloor(atX: onTheEdge, fromTopY: 1980) == 1080)

  let sideBySide = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1920, height: 1080),
  ])
  let boundary = 1440.0
  let boundaryCenter = TerminalStyle.snapToGrid(x: boundary) + TerminalStyle.cellWidth / 2
  #expect(sideBySide.highestScreen(atX: boundaryCenter)?.index == 0)
  #expect(sideBySide.highestScreen(atX: boundary)?.index == 1)
}

@Test("Un point couvert par deux écrans appartient au plus haut")
func pointCoveredByTwoScreensBelongsToTheHigherOne() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1920, height: 1081),
    TerminalScreen(index: 1, x: 240, y: 1080, width: 1440, height: 900),
  ])
  #expect(layout.screen(atX: 500, y: 1080.5)?.index == 1)
  #expect(layout.screen(atX: 100, y: 500)?.index == 0)
}

@Test("Un seul écran est du haut et la colonne s’arrête à son bas")
func singleScreenIsTheTopAndTheColumnStopsAtItsFloor() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)
  ])
  #expect(layout.topScreenIndices == [0])
  #expect(layout.fallFloor(atX: 720, fromTopY: 900) == 0)
}

@Test("Deux écrans côte à côte sont tous les deux du haut")
func sideBySideScreensAreBothTopAndDoNotShareAColumn() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1920, height: 1080),
  ])
  #expect(layout.topScreenIndices == [0, 1])
  #expect(layout.highestScreen(atX: 100)?.index == 0)
  #expect(layout.highestScreen(atX: 2000)?.index == 1)
  #expect(layout.fallFloor(atX: 100, fromTopY: 900) == 0)
  #expect(layout.fallFloor(atX: 2000, fromTopY: 1080) == 0)
}

@Test("Une colonne née sur l’écran du haut coule jusqu’au bas de l’écran du dessous")
func stackedScreensFlowFromTheUpperScreenOntoTheLowerOne() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 240, y: 1080, width: 1440, height: 900),
  ])
  #expect(layout.topScreenIndices == [1])
  #expect(layout.fallFloor(atX: 500, fromTopY: 1980) == 0)
  #expect(layout.fallFloor(atX: 100, fromTopY: 1080) == 0)
}

@Test("Un décalage partiel arrête la colonne là où l’écran du dessous s’arrête")
func partialOverlapFlowsOnlyWhereTheLowerScreenContinues() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 1500, y: 1080, width: 1440, height: 900),
  ])
  #expect(layout.fallFloor(atX: 1600, fromTopY: 1980) == 0)
  #expect(layout.fallFloor(atX: 2500, fromTopY: 1980) == 1080)
}

@Test("Un écran à gauche, en x négatifs, garde sa propre colonne")
func leftScreenWithNegativeXKeepsItsOwnColumn() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: -1920, y: 200, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 0, y: 0, width: 1440, height: 900),
  ])
  #expect(layout.topScreenIndices == [0, 1])
  #expect(layout.highestScreen(atX: -100)?.index == 0)
  #expect(layout.fallFloor(atX: -100, fromTopY: 1280) == 200)
  #expect(layout.fallFloor(atX: 100, fromTopY: 900) == 0)
}

@Test("Un écart d’un point coule, un écart de cinquante points s’arrête")
func onePointGapFlowsAndFiftyPointGapStops() {
  let flowing = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 0, y: 901, width: 1440, height: 900),
  ])
  #expect(flowing.topScreenIndices == [1])
  #expect(flowing.fallFloor(atX: 100, fromTopY: 1801) == 0)
  #expect(flowing.screen(atX: 100, y: 900.5) == nil)

  let stopped = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 0, y: 950, width: 1440, height: 900),
  ])
  #expect(stopped.topScreenIndices == [1])
  #expect(stopped.fallFloor(atX: 100, fromTopY: 1850) == 950)
}

@Test("Trois écrans empilés laissent la colonne traverser les trois")
func threeStackedScreensAreCrossedByOneColumn() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 800),
    TerminalScreen(index: 1, x: 0, y: 800, width: 1440, height: 800),
    TerminalScreen(index: 2, x: 0, y: 1600, width: 1440, height: 800),
  ])
  #expect(layout.topScreenIndices == [2])
  #expect(layout.fallFloor(atX: 400, fromTopY: 2400) == 0)
}

@Test("Les abscisses aléatoires naissent sur un écran du haut, alignées sur la grille")
func randomSpawnXsLandOnTopScreensAlongTheGrid() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1920, height: 1080),
  ])
  var rng = SplitMix64(seed: 1)
  var sawLeft = false
  var sawRight = false
  for _ in 0..<40 {
    let spawns = layout.randomSpawnXs(count: 1, using: &rng)
    #expect(spawns.count == 1)
    let spawn = spawns[0]
    #expect(spawn.x.truncatingRemainder(dividingBy: TerminalStyle.cellWidth) == 0)
    let onLeft = spawn.topY == 900 && spawn.x >= 0 && spawn.x <= 1440 - TerminalStyle.cellWidth
    let onRight = spawn.topY == 1080 && spawn.x >= 1440 && spawn.x <= 3360 - TerminalStyle.cellWidth
    #expect(onLeft || onRight)
    if onLeft { sawLeft = true }
    if onRight { sawRight = true }
  }
  #expect(sawLeft)
  #expect(sawRight)
}

@Test("Un même appel évite les abscisses en double tant que la grille le permet")
func randomSpawnXsAvoidsDuplicateAbscissasWhileSlotsRemain() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 10, width: 102, height: 100)
  ])
  var rng = SplitMix64(seed: 7)
  let spawns = layout.randomSpawnXs(count: 6, using: &rng)
  #expect(spawns.map(\.x).sorted() == [0, 17, 34, 51, 68, 85])
  #expect(spawns.allSatisfy { $0.topY == 110 })
}

@Test("Les abscisses se répètent une fois chaque colonne de grille prise")
func randomSpawnXsRepeatsOnceEveryGridSlotIsTaken() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: 0, y: 0, width: 34, height: 100)
  ])
  var rng = SplitMix64(seed: 1)
  let spawns = layout.randomSpawnXs(count: 4, using: &rng)
  #expect(spawns.count == 4)
  #expect(spawns.allSatisfy { $0.topY == 100 && ($0.x == 0 || $0.x == 17) })
  #expect(Set(spawns.map(\.x)) == [0, 17])
}

@Test("Une abscisse tirée sur un écran à gauche reste sur sa grille")
func randomSpawnXsOnALeftScreenStaysOnThatGrid() {
  let layout = TerminalScreenLayout(screens: [
    TerminalScreen(index: 0, x: -1920, y: 200, width: 1920, height: 1080)
  ])
  var rng = SplitMix64(seed: 2)
  let spawns = layout.randomSpawnXs(count: 5, using: &rng)
  #expect(spawns.count == 5)
  #expect(Set(spawns.map(\.x)).count == 5)
  for spawn in spawns {
    #expect(spawn.topY == 1280)
    #expect(spawn.x >= -1920)
    #expect(spawn.x <= -17)
    #expect(spawn.x.truncatingRemainder(dividingBy: TerminalStyle.cellWidth) == 0)
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
