import ApplicationServices
import AppKit
import Carbon
import CmdBabyKit

/// Chien de garde d’une session active : toutes les 0,5 s, vérifie que la protection tient encore.
@MainActor
final class SessionWatchdog {
  private let filter: () -> SessionInputFilter?
  private let covers: CoverWindowCoordinator
  private let log: LifecycleLogRecorder
  private var timer: Timer?
  private var tapWasEnabled = true
  private var warnings: Set<SessionGuardWarning> = []

  init(
    filter: @escaping () -> SessionInputFilter?,
    covers: CoverWindowCoordinator,
    log: LifecycleLogRecorder = .shared
  ) {
    self.filter = filter
    self.covers = covers
    self.log = log
  }

  func start() {
    stop()
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.check()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    tapWasEnabled = true
    warnings = []
    covers.showParentWarning(false)
  }

  private func check() {
    let tapEnabled = filter()?.isTapEnabled() ?? false
    let actions = SessionGuard.evaluate(
      tapEnabled: tapEnabled,
      accessibilityTrusted: AXIsProcessTrusted(),
      secureInputActive: IsSecureEventInputEnabled(),
      appActive: NSApp.isActive
    )
    if !tapEnabled && tapWasEnabled {
      log.emit(.guardTapLost)
    }
    tapWasEnabled = tapEnabled

    var current: Set<SessionGuardWarning> = []
    for action in actions {
      switch action {
      case .reenableTap:
        filter()?.reenableTapIfPossible()
      case .refocusCovers:
        log.emit(.guardRefocus)
        covers.refocus()
      case .warnParent(let warning):
        current.insert(warning)
      }
    }
    if current.contains(.secureInput) && !warnings.contains(.secureInput) {
      log.emit(.guardSecureInput)
    }
    warnings = current
    covers.showParentWarning(!current.isEmpty)
  }
}
