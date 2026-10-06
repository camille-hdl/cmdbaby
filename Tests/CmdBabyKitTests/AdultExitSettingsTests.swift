import Testing

@testable import CmdBabyKit

@Test("Un minuteur neuf dure 3 minutes, entre 1 et 120")
func freshTimeLimitLastsThreeMinutesWithinTheExistingRange() {
  #expect(AdultExitSettings().timeLimitMinutes == 3)
  #expect(AdultExitSettings.timeLimitRange == 1...120)
}
