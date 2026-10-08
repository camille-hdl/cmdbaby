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

@Test("Les planètes standard sont les plus lentes, immenses, rares et un peu atténuées")
func starshipTuningStandardPlanetsAreDistant() {
  let tuning = StarshipTuning.standard
  let planet = tuning.scenery(for: .planet)
  let far = tuning.scenery(for: .farAsteroid)

  #expect(abs(planet.depth - 6) < 1e-6)
  #expect(planet.depth > far.depth)
  #expect(planet.sizeFractionOfTallestScreen == 0.30...0.60)
  #expect(abs(planet.opacity - 0.7) < 1e-6)
  #expect(planet.opacity < 1)
  #expect(planet.ceiling == 2)
  #expect(abs(planet.meanInterval - 90) < 1e-6)
  #expect(planet.meanInterval > far.meanInterval)
}

@Test("Le décor standard défile lentement, peu d’astéroïdes, les proches plus grands")
func starshipTuningStandardSceneryIsCalm() {
  let tuning = StarshipTuning.standard
  let far = tuning.scenery(for: .farAsteroid)
  let near = tuning.scenery(for: .nearAsteroid)

  #expect(abs(tuning.sceneryReferenceSpeed - 80) < 1e-6)
  #expect(abs(far.depth - 4) < 1e-6)
  #expect(abs(near.depth - 2) < 1e-6)
  #expect(abs(far.size - 56) < 1e-6)
  #expect(abs(near.size - 96) < 1e-6)
  #expect(near.size > far.size)
  #expect(abs(far.opacity - 0.28) < 1e-6)
  #expect(abs(near.opacity - 0.5) < 1e-6)
  #expect(far.opacity < near.opacity)
  #expect(near.opacity < 1)
  #expect(far.ceiling == 2)
  #expect(near.ceiling == 2)
  #expect(abs(far.meanInterval - 18) < 1e-6)
  #expect(abs(near.meanInterval - 12) < 1e-6)
}
