import Testing

@testable import CmdBabyKit

@Test("Une demande de colonne donne une colonne")
func columnRequestYieldsOneColumn() {
  var rng = SplitMix64(seed: 1)
  let count = TerminalRainPlanner.columnCount(for: .column, tuning: .standard, using: &rng)
  #expect(count == 1)
}

@Test("Une vague reste dans 3…6 et les quatre valeurs apparaissent")
func waveRequestCoversStandardRange() {
  var rng = SplitMix64(seed: 1)
  var seen: Set<Int> = []
  for _ in 0..<1_000 {
    let count = TerminalRainPlanner.columnCount(for: .wave, tuning: .standard, using: &rng)
    #expect((3...6).contains(count))
    seen.insert(count)
  }
  #expect(seen == [3, 4, 5, 6])
}

@Test("Toute la demande passe quand il reste de la place")
func admissibleCountKeepsTheRequestWhenRoomRemains() {
  let tuning = TerminalRainTuning(maxActiveColumns: 400)
  let count = TerminalRainPlanner.admissibleCount(requested: 6, active: 10, tuning: tuning)
  #expect(count == 6)
}

@Test("Une vague est tronquée à la place qui reste")
func admissibleCountTruncatesAWaveToTheRemainingRoom() {
  let tuning = TerminalRainTuning(maxActiveColumns: 400)
  let count = TerminalRainPlanner.admissibleCount(requested: 6, active: 397, tuning: tuning)
  #expect(count == 3)
}

@Test("Aucune colonne ne part une fois le plafond atteint")
func admissibleCountIsZeroOnceTheCeilingIsReached() {
  let tuning = TerminalRainTuning(maxActiveColumns: 400)
  #expect(TerminalRainPlanner.admissibleCount(requested: 4, active: 400, tuning: tuning) == 0)
  #expect(TerminalRainPlanner.admissibleCount(requested: 4, active: 401, tuning: tuning) == 0)
}

@Test("Les abscisses sont distinctes, alignées sur la grille et dans les bornes")
func distinctGridXsStayOnTheGridInsideTheScreen() {
  var rng = SplitMix64(seed: 7)
  let xs = TerminalRainPlanner.distinctGridXs(count: 4, minX: 10, maxX: 200, using: &rng)
  #expect(xs.count == 4)
  #expect(Set(xs).count == 4)
  for x in xs {
    #expect(x >= 10)
    #expect(x <= 200 - 17)
    #expect(x.truncatingRemainder(dividingBy: 17) == 0)
  }
}

@Test("Un écran plus étroit qu’une cellule ne donne aucune abscisse")
func distinctGridXsOnANarrowScreenIsEmpty() {
  var rng = SplitMix64(seed: 1)
  let xs = TerminalRainPlanner.distinctGridXs(count: 3, minX: 0, maxX: 16, using: &rng)
  #expect(xs == [])
}

@Test("Un écran trop court pour la demande renvoie toutes les colonnes qui y tiennent")
func distinctGridXsReturnsEverySlotWhenTheScreenIsShort() {
  var rng = SplitMix64(seed: 1)
  let xs = TerminalRainPlanner.distinctGridXs(count: 6, minX: 0, maxX: 34, using: &rng)
  #expect(xs.sorted() == [0, 17])
}

@Test("Les abscisses suivent la grille quand l’écran est à gauche de l’origine")
func distinctGridXsFollowsTheGridLeftOfTheOrigin() {
  var rng = SplitMix64(seed: 1)
  let xs = TerminalRainPlanner.distinctGridXs(count: 5, minX: -40, maxX: 20, using: &rng)
  #expect(xs.sorted() == [-34, -17, 0])
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
