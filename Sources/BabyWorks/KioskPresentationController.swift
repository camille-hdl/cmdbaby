import AppKit
import BabyWorkAppKitBridge
import BabyWorkDiagnosticsKit

/// Applique et restaure `NSApplication.presentationOptions` sans substituer une valeur par défaut.
@MainActor
final class KioskPresentationController {
  func capture() -> PresentationOptionsSnapshot {
    PresentationOptionsSnapshot(rawValue: NSApp.presentationOptions.rawValue)
  }

  func applyKiosk() throws {
    let snapshot = KioskPresentationPolicy.kiosk
    guard KioskPresentationPolicy.isValid(snapshot) else {
      throw KioskSessionError.presentationRejected
    }
    if #available(macOS 14, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
    guard BabyWorkTrySetPresentationOptions(UInt64(snapshot.rawValue)) else {
      throw KioskSessionError.presentationRejected
    }
  }

  func restore(_ snapshot: PresentationOptionsSnapshot) {
    _ = BabyWorkTrySetPresentationOptions(UInt64(snapshot.rawValue))
  }
}
