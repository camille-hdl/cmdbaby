import Testing

@testable import CmdBabyKit

@Test("La dérive du ciel descend une fois, sans retour ni saut vers le haut")
func skyboxDriftDescendsOnceWithoutReversingOrJumping() throws {
  let screens = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
  let from = try #require(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 0, verticalMargin: 0.40
    )
  )
  let to = try #require(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 1, verticalMargin: 0.40
    )
  )
  let drift = StarshipSkyboxDrift.once(from: from, to: to, duration: 180)

  // Écran 1440 × 900, marge 0,40 : y passe de 0 à 0,40. Le ciel visible descend.
  #expect(abs(drift.from.x - 0.26) < 1e-5)
  #expect(abs(drift.from.y - 0) < 1e-5)
  #expect(abs(drift.from.width - 0.48) < 1e-5)
  #expect(abs(drift.from.height - 0.60) < 1e-5)
  #expect(abs(drift.to.x - 0.26) < 1e-5)
  #expect(abs(drift.to.y - 0.40) < 1e-5)
  #expect(abs(drift.to.width - 0.48) < 1e-5)
  #expect(abs(drift.to.height - 0.60) < 1e-5)
  #expect(drift.to.y > drift.from.y)
  #expect(drift.reverses == false)
  // 0 joue une fois. Répéter, même sans retour, ramène y au départ : le ciel saute vers le haut.
  #expect(drift.repeatCount == 0)
  #expect(drift.repeatDuration == 0)
  #expect(abs(drift.duration - 180) < 1e-6)
}
