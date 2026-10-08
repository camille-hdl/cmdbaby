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

@Test("La skybox standard change toutes les 30 s et fond en 2 s")
func starshipTuningStandardSkybox() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.skyboxInterval - 30) < 1e-6)
  #expect(abs(tuning.skyboxFadeDuration - 2) < 1e-6)
}

@Test("La dérive standard zoome à 40 % de marge et descend pendant les 3 min d’une session")
func starshipTuningStandardSkyboxDrift() {
  let tuning = StarshipTuning.standard
  #expect(abs(tuning.skyboxDriftMargin - 0.40) < 1e-6)
  #expect(tuning.skyboxDriftMargin > 0.10)
  #expect(abs(tuning.skyboxDriftDuration - 180) < 1e-6)
  #expect(tuning.skyboxDriftDuration >= 60)
}

@Test("Sur un écran 1440 × 900, le ciel standard descend à 3,3 pt/s pendant 3 min, plus lent que les planètes")
func standardSkyboxDriftDescendsSlowerThanPlanets() {
  let tuning = StarshipTuning.standard
  let screens = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
  let from = StarshipSkyboxFraming.contentsRect(
    forScreen: 0, among: screens, drift: 0, verticalMargin: tuning.skyboxDriftMargin
  )
  let to = StarshipSkyboxFraming.contentsRect(
    forScreen: 0, among: screens, drift: 1, verticalMargin: tuning.skyboxDriftMargin
  )
  #expect(from != nil)
  #expect(to != nil)
  guard let from, let to else { return }

  // L’origine de contentsRect est en bas à gauche : y augmente, le ciel visible descend.
  // Fenêtre haute de 0,60 : 0,40 / 0,60 × 900 pt = 600 pt, en 180 s, soit 10/3 pt/s.
  #expect(to.y > from.y)
  #expect(abs(from.height - 0.60) < 1e-6)
  #expect(abs(to.y - from.y - 0.40) < 1e-6)
  let points = (to.y - from.y) / from.height * 900
  let skySpeed = points / tuning.skyboxDriftDuration
  #expect(abs(points - 600) < 1e-6)
  #expect(abs(skySpeed - 10.0 / 3.0) < 1e-6)
  #expect(skySpeed < 80)
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

@Test("Le décor standard défile vite, peu d’astéroïdes, les proches plus grands")
func starshipTuningStandardSceneryScrollsFastWithFewAsteroidsAndLargerNearOnes() {
  let tuning = StarshipTuning.standard
  let far = tuning.scenery(for: .farAsteroid)
  let near = tuning.scenery(for: .nearAsteroid)

  #expect(abs(tuning.sceneryReferenceSpeed - 480) < 1e-6)
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

@Test("Les traits de vitesse standard sont nombreux, fins, peu opaques et plus rapides que les astéroïdes")
func starshipTuningStandardSpeedStreaksAreFaint() {
  let tuning = StarshipTuning.standard
  let streak = tuning.scenery(for: .speedStreak)
  let near = tuning.scenery(for: .nearAsteroid)

  #expect(streak.depth < near.depth)
  // 480 / 0,375 = 1 280 pt/s : le trait reste le plus rapide, sans devenir un flash.
  #expect(abs(streak.depth - 0.375) < 1e-9)
  #expect(abs(streak.size - 64) < 1e-6)
  #expect(abs(tuning.speedStreakWidth - 2) < 1e-6)
  #expect(tuning.speedStreakWidth >= 1)
  #expect(tuning.speedStreakWidth <= 3)
  #expect(abs(streak.opacity - 0.2) < 1e-6)
  #expect(streak.opacity <= 0.3)
  #expect(streak.opacity > 0)
  #expect(streak.ceiling == 8)
  #expect(streak.ceiling >= 6)
  #expect(streak.meanInterval == 0.125)
  #expect(streak.meanInterval < 1)
  #expect(abs(tuning.speedStreakCorridorWidth - 200) < 1e-6)
  #expect(tuning.speedStreakCorridorWidth > tuning.shipWidth)
  #expect(tuning.speedStreakColor == StarshipRGB(hex: 0xFFFFFF))
}
