import CmdBabyKit
import IOKit.pwr_mgt

/// Empêche l’écran de s’éteindre ou de passer à l’économiseur pendant une session.
/// Le minuteur de session reste la limite de durée.
@MainActor
final class DisplaySleepAssertion {
  private var assertionID: IOPMAssertionID?

  func take() {
    guard assertionID == nil else { return }
    var id = IOPMAssertionID(0)
    let result = IOPMAssertionCreateWithName(
      kIOPMAssertPreventUserIdleDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      "\(AppIdentity.displayName) session" as CFString,
      &id
    )
    guard result == kIOReturnSuccess else { return }
    assertionID = id
    LifecycleLogRecorder.shared.emit(.displaySleepAssertion(taken: true))
  }

  func release() {
    guard let assertionID else { return }
    IOPMAssertionRelease(assertionID)
    self.assertionID = nil
    LifecycleLogRecorder.shared.emit(.displaySleepAssertion(taken: false))
  }
}
