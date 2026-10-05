import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Pendant 3 s, le vaisseau reste sur le plus grand écran, même si le curseur est ailleurs")
func starshipStaysOnTheLargestScreenDuringTheOpeningDelay() {
  let tuning = StarshipTuning.standard
  let screens = largeAndSmallScreens()

  #expect(
    StarshipScreenChoice.index(
      sessionAge: 0,
      pointerScreenIndex: 0,
      screens: screens,
      tuning: tuning
    ) == 1
  )
  #expect(
    StarshipScreenChoice.index(
      sessionAge: 2.999,
      pointerScreenIndex: 0,
      screens: screens,
      tuning: tuning
    ) == 1
  )
}

@Test("Après 3 s, le vaisseau suit l’écran du curseur")
func starshipFollowsThePointerScreenAfterThreeSeconds() {
  let tuning = StarshipTuning.standard
  let screens = largeAndSmallScreens()

  #expect(
    StarshipScreenChoice.index(
      sessionAge: 3,
      pointerScreenIndex: 0,
      screens: screens,
      tuning: tuning
    ) == 0
  )
  #expect(
    StarshipScreenChoice.index(
      sessionAge: 5,
      pointerScreenIndex: nil,
      screens: screens,
      tuning: tuning
    ) == 1
  )
  #expect(
    StarshipScreenChoice.index(
      sessionAge: 5,
      pointerScreenIndex: 9,
      screens: screens,
      tuning: tuning
    ) == 1
  )
}

private func largeAndSmallScreens() -> [TerminalScreen] {
  [
    TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600),
    TerminalScreen(index: 1, x: 800, y: 0, width: 1920, height: 1080),
  ]
}
