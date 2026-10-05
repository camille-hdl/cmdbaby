import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le niveau est la cadence divisée par le plafond, bornée entre 0 et 1")
func starshipGaugeLevelIsCappedRatio() {
  #expect(StarshipGauge.level(perMinute: 150, cap: 300) == 0.5)
  #expect(StarshipGauge.level(perMinute: 450, cap: 300) == 1)
  #expect(StarshipGauge.level(perMinute: -5, cap: 300) == 0)
}

@Test("La couleur suit les paliers vert, jaune, orange et rouge vif")
func starshipGaugeColorHitsTheStops() {
  #expect(StarshipGauge.color(level: 0) == StarshipRGB(hex: 0x2ECC71))
  #expect(StarshipGauge.color(level: 0.5) == StarshipRGB(hex: 0xF1C40F))
  #expect(StarshipGauge.color(level: 0.8) == StarshipRGB(hex: 0xFF8C00))
  #expect(StarshipGauge.color(level: 1) == StarshipRGB(red: 1, green: 0, blue: 0))
  #expect(StarshipGauge.color(level: 2) == StarshipRGB(red: 1, green: 0, blue: 0))
}

@Test("La couleur s’interpole entre les paliers")
func starshipGaugeColorInterpolatesBetweenStops() {
  let atNineTenths = StarshipGauge.color(level: 0.9)
  #expect(abs(atNineTenths.red - 1) < 1e-6)
  #expect(abs(atNineTenths.green - 70.0 / 255) < 1e-6)
  #expect(abs(atNineTenths.blue - 0) < 1e-6)

  let midway = StarshipGauge.color(level: 0.25)
  #expect(abs(midway.red - 143.5 / 255) < 1e-6)
  #expect(abs(midway.green - 200.0 / 255) < 1e-6)
  #expect(abs(midway.blue - 64.0 / 255) < 1e-6)
}

@Test("La jauge se rapproche du niveau visé sans le dépasser d’un coup")
func starshipGaugeEasesTowardTheTarget() {
  let up = StarshipGauge.eased(current: 0, target: 1, dt: 1.0 / 60)
  let down = StarshipGauge.eased(current: 1, target: 0, dt: 1.0 / 60)
  let jumped = StarshipGauge.eased(current: 0, target: 1, dt: 1)
  #expect(abs(up - 8.0 / 60) < 1e-6)
  #expect(abs(down - (1 - 8.0 / 60)) < 1e-6)
  #expect(abs(jumped - 1) < 1e-6)
}
