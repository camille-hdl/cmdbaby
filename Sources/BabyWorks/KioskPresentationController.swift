import AppKit
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
    NSApp.presentationOptions = NSApplication.PresentationOptions(rawValue: snapshot.rawValue)
  }

  func restore(_ snapshot: PresentationOptionsSnapshot) {
    NSApp.presentationOptions = NSApplication.PresentationOptions(rawValue: snapshot.rawValue)
  }
}
