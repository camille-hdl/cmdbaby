import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Une touche compte 6 pendant 10 s, puis sort de la fenêtre")
func starshipKeyRateCountsOneKeyForTenSeconds() {
  var rate = StarshipKeyRate(window: 10, cap: 300)
  #expect(rate.perMinute(at: 0) == 0)

  rate.record(at: 0)
  #expect(rate.perMinute(at: 0) == 6)
  #expect(rate.perMinute(at: 9.9) == 6)
  #expect(rate.perMinute(at: 10) == 0)
}

@Test("Dix touches en une seconde donnent 60 touches par minute")
func starshipKeyRateTenKeysInOneSecondAreSixtyPerMinute() {
  var rate = StarshipKeyRate(window: 10, cap: 300)
  for index in 0..<10 {
    rate.record(at: Double(index) / 10)
  }
  #expect(rate.perMinute(at: 1) == 60)
}

@Test("Quatre-vingts touches en 8 s plafonnent à 300")
func starshipKeyRateEightyKeysAreCappedAtThreeHundred() {
  var rate = StarshipKeyRate(window: 10, cap: 300)
  for index in 0..<80 {
    rate.record(at: Double(index) * 8 / 79)
  }
  #expect(rate.perMinute(at: 8) == 300)
}

@Test("Vingt secondes sans frappe vident la cadence et son stockage")
func starshipKeyRateGoesIdleAndMatchesAFreshValue() {
  var rate = StarshipKeyRate(window: 10, cap: 300)
  for index in 0..<1_000 {
    rate.record(at: Double(index) * 0.001)
  }
  #expect(rate.perMinute(at: 20) == 0)
  #expect(rate == StarshipKeyRate(window: 10, cap: 300))
}
