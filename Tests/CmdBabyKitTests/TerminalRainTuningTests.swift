import Testing

@testable import CmdBabyKit

@Test("standard fixe la vitesse, la densité et le plafond de 400 colonnes")
func terminalRainTuningStandardMatchesFilm() {
  let tuning = TerminalRainTuning.standard
  #expect(tuning.stepIntervalRange == (1.0 / 24)...(1.0 / 14))
  #expect(tuning.speedMultiplier == 1)
  #expect(tuning.trailLifetimeRange == 1.2...2.0)
  #expect(tuning.flickerProbabilityPerTick == 0.02)
  #expect(tuning.waveColumnRange == 3...6)
  #expect(tuning.maxActiveColumns == 400)
  #expect(tuning.maxLiveCellsPerScreen == 20_000)
}

@Test("stepInterval(roll: 0) et un roll proche de 1 donnent les bornes de l’intervalle")
func terminalRainTuningStepIntervalReachesRangeBounds() {
  let tuning = TerminalRainTuning.standard
  #expect(tuning.stepInterval(roll: 0) == 1.0 / 24)
  let nearUpper = tuning.stepInterval(roll: 1.nextDown)
  #expect(abs(nearUpper - 1.0 / 14) < 1e-9)
}

@Test("speedMultiplier divise l’intervalle et reste borné entre 0,25 et 4")
func terminalRainTuningClampsSpeedMultiplier() {
  let doubled = TerminalRainTuning(speedMultiplier: 2)
  #expect(doubled.speedMultiplier == 2)
  #expect(doubled.stepInterval(roll: 0) == (1.0 / 24) / 2)

  let tooFast = TerminalRainTuning(speedMultiplier: 10)
  #expect(tooFast.speedMultiplier == 4)
  #expect(tooFast.stepInterval(roll: 0) == (1.0 / 24) / 4)

  let tooSlow = TerminalRainTuning(speedMultiplier: 0)
  #expect(tooSlow.speedMultiplier == 0.25)
  #expect(tooSlow.stepInterval(roll: 0) == (1.0 / 24) / 0.25)
}

@Test("trailLifetime(roll: 0) et un roll proche de 1 donnent les bornes de vie")
func terminalRainTuningTrailLifetimeReachesRangeBounds() {
  let tuning = TerminalRainTuning.standard
  #expect(tuning.trailLifetime(roll: 0) == 1.2)
  let nearUpper = tuning.trailLifetime(roll: 1.nextDown)
  #expect(abs(nearUpper - 2) < 1e-9)
}
