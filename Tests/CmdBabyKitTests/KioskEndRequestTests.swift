import Testing

@testable import CmdBabyKit

@Test(
  "Une sortie adulte ne termine pas le process",
  arguments: [
    AdultExitKind.passphrase,
    .shiftEscape,
    .failsafeClick,
    .timeLimit,
  ]
)
func adultExitDoesNotTerminateProcess(kind: AdultExitKind) {
  #expect(KioskEndRequest.adultExit(kind).terminatesProcess == false)
}

@Test("Quitter explicitement termine le process")
func explicitQuitTerminatesProcess() {
  #expect(KioskEndRequest.explicitQuit.terminatesProcess == true)
}
