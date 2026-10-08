import Testing

@testable import CmdBabyKit

@Test("Le vaisseau standard mesure 140 pt, se déplace en 0,25 s et vise en 0,1 s")
func starshipTuningStandardShip() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.shipWidth - 140) < 1e-6)
  #expect(abs(tuning.shipWarpDuration - 0.25) < 1e-6)
  #expect(abs(tuning.spinDuration - 0.6) < 1e-6)
  #expect(abs(tuning.aimDuration - 0.1) < 1e-6)
  #expect(abs(tuning.screenChangeDelay - 3) < 1e-6)
}

@Test("Les cibles standard font 110 pt, accélèrent et explosent au bouclier")
func starshipTuningStandardTargets() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.targetWidth - 110) < 1e-6)
  #expect(abs(tuning.glyphFontSize - 56) < 1e-6)
  #expect(abs(tuning.initialSpeedRange.lowerBound - 60) < 1e-6)
  #expect(abs(tuning.initialSpeedRange.upperBound - 140) < 1e-6)
  #expect(abs(tuning.accelerationRange.lowerBound - 80) < 1e-6)
  #expect(abs(tuning.accelerationRange.upperBound - 220) < 1e-6)
  #expect(abs(tuning.maxSpeed - 600) < 1e-6)
  #expect(abs(tuning.shieldRadius - 120) < 1e-6)
  #expect(tuning.maxTargets == 30)
}

@Test("Le tir standard attend au moins 2 s et file à 1800 pt/s")
func starshipTuningStandardFire() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.fireDelayRange.lowerBound - 2) < 1e-6)
  #expect(abs(tuning.fireDelayRange.upperBound - 2.6) < 1e-6)
  #expect(abs(tuning.minimumFireDelay - 2) < 1e-6)
  #expect(abs(tuning.fireSafetyMargin - 80) < 1e-6)
  #expect(abs(tuning.boltSpeed - 1800) < 1e-6)
  #expect(abs(tuning.boltOvershoot - 80) < 1e-6)
  #expect(abs(tuning.beamDuration - 0.15) < 1e-6)
  #expect(abs(tuning.explosionDuration - 0.35) < 1e-6)
}

@Test("La skybox standard change toutes les 60 s et fond en 2 s")
func starshipTuningStandardSkybox() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.skyboxInterval - 60) < 1e-6)
  #expect(abs(tuning.skyboxFadeDuration - 2) < 1e-6)
}

@Test("La jauge standard compte 10 s et sature à 300 touches par minute")
func starshipTuningStandardGauge() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.keyRateWindow - 10) < 1e-6)
  #expect(abs(tuning.keyRateCap - 300) < 1e-6)
}

@Test("Le vaisseau garde au plus trois tours en attente")
func starshipTuningStandardSpinBacklog() {
  #expect(abs(StarshipTuning.standard.spinBacklog - 1.8) < 1e-6)
}

@Test("Le vaisseau standard se tient à 18 % de la hauteur depuis le bas")
func starshipTuningStandardShipRestsNearTheBottom() {
  #expect(abs(StarshipTuning.standard.shipCenterFromBottom - 0.18) < 1e-6)
}
