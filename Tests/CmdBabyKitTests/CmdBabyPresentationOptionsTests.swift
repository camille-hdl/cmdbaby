import AppKit
import CmdBabyAppKitBridge
import Testing

@Test("HideDock combiné à AutoHideDock est refusé sans faire planter le process")
@MainActor
func mutuallyExclusiveDockOptionsAreRejectedWithoutCrashing() {
  _ = NSApplication.shared
  let hideDockAndAutoHideDock: UInt64 = 0x3
  #expect(CmdBabyTrySetPresentationOptions(hideDockAndAutoHideDock) == false)
}

@Test("L’absence d’options de présentation est acceptée")
@MainActor
func emptyPresentationOptionsAreAccepted() {
  _ = NSApplication.shared
  #expect(CmdBabyTrySetPresentationOptions(0) == true)
}
