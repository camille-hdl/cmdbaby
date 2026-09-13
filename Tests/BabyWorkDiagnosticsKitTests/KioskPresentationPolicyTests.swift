import Testing

@testable import BabyWorkDiagnosticsKit

@Test("La combinaison kiosque est valide")
func kioskPresentationCombinationIsValid() {
  #expect(KioskPresentationPolicy.isValid(KioskPresentationPolicy.kiosk))
  #expect(KioskPresentationPolicy.isValid(PresentationOptionsSnapshot(rawValue: 0)))
}

@Test("Les combinaisons AppKit mutuellement exclusives sont rejetées")
func mutuallyExclusivePresentationOptionsAreRejected() {
  let hideDockAndAutoHideDock = PresentationOptionsSnapshot(
    rawValue: KioskPresentationPolicy.hideDock | KioskPresentationPolicy.autoHideDock
  )
  let hideAndAutoHideMenuBar = PresentationOptionsSnapshot(
    rawValue: KioskPresentationPolicy.hideDock | KioskPresentationPolicy.hideMenuBar
      | KioskPresentationPolicy.autoHideMenuBar
  )
  let hideMenuBarWithoutDock = PresentationOptionsSnapshot(
    rawValue: KioskPresentationPolicy.hideMenuBar
  )
  let fullScreenWithoutAutoHideMenuBar = PresentationOptionsSnapshot(
    rawValue: KioskPresentationPolicy.fullScreen | KioskPresentationPolicy.hideDock
      | KioskPresentationPolicy.hideMenuBar
  )

  #expect(!KioskPresentationPolicy.isValid(hideDockAndAutoHideDock))
  #expect(!KioskPresentationPolicy.isValid(hideAndAutoHideMenuBar))
  #expect(!KioskPresentationPolicy.isValid(hideMenuBarWithoutDock))
  #expect(!KioskPresentationPolicy.isValid(fullScreenWithoutAutoHideMenuBar))
}
