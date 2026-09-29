import AppKit
import BabyWorkAppKitBridge
import Testing

@Test("HideDock combiné à AutoHideDock est refusé sans faire planter le process")
@MainActor
func mutuallyExclusiveDockOptionsAreRejectedWithoutCrashing() {
  _ = NSApplication.shared
  let hideDockAndAutoHideDock: UInt64 = 0x3
  #expect(BabyWorkTrySetPresentationOptions(hideDockAndAutoHideDock) == false)
}

@Test("L’absence d’options de présentation est acceptée")
@MainActor
func emptyPresentationOptionsAreAccepted() {
  _ = NSApplication.shared
  #expect(BabyWorkTrySetPresentationOptions(0) == true)
}
