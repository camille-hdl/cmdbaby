import AppKit
import Testing

@testable import CmdBabyKit

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

@Test("Les bits suivent NSApplication.PresentationOptions")
func presentationBitsMatchAppKit() {
  #expect(KioskPresentationPolicy.autoHideDock == NSApplication.PresentationOptions.autoHideDock.rawValue)
  #expect(KioskPresentationPolicy.hideDock == NSApplication.PresentationOptions.hideDock.rawValue)
  #expect(KioskPresentationPolicy.autoHideMenuBar == NSApplication.PresentationOptions.autoHideMenuBar.rawValue)
  #expect(KioskPresentationPolicy.hideMenuBar == NSApplication.PresentationOptions.hideMenuBar.rawValue)
  #expect(KioskPresentationPolicy.disableAppleMenu == NSApplication.PresentationOptions.disableAppleMenu.rawValue)
  #expect(
    KioskPresentationPolicy.disableProcessSwitching
      == NSApplication.PresentationOptions.disableProcessSwitching.rawValue
  )
  #expect(KioskPresentationPolicy.disableForceQuit == NSApplication.PresentationOptions.disableForceQuit.rawValue)
  #expect(
    KioskPresentationPolicy.disableSessionTermination
      == NSApplication.PresentationOptions.disableSessionTermination.rawValue
  )
  #expect(
    KioskPresentationPolicy.disableHideApplication
      == NSApplication.PresentationOptions.disableHideApplication.rawValue
  )
  #expect(KioskPresentationPolicy.fullScreen == NSApplication.PresentationOptions.fullScreen.rawValue)
}

@Test("La combinaison kiosque est celle qu’AppKit accepte")
func kioskCombinationMatchesAppKitOptions() {
  let expected: NSApplication.PresentationOptions = [
    .hideDock, .hideMenuBar, .disableAppleMenu, .disableProcessSwitching,
    .disableForceQuit, .disableSessionTermination, .disableHideApplication,
  ]
  #expect(KioskPresentationPolicy.kiosk.rawValue == expected.rawValue)
}
