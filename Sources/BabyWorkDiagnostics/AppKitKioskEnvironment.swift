import AppKit
import BabyWorkDiagnosticsKit
import Foundation
import OSLog

/// Pont AppKit pour le contrôleur de kiosque : écrans vivants, présentation, filtre.
@MainActor
final class AppKitKioskEnvironment: KioskSessionServices {
  var onFilterStatus: (@Sendable (InputFilterStatus) -> Void)?
  var onCountsChange: (@Sendable ([MonitoredShortcut: Int]) -> Void)?
  var onHideDiagnosticInterface: (() -> Void)?
  var onRevealDiagnosticInterface: (() -> Void)?

  let emergency: KioskEmergencyExit
  let terminationGate: TerminationGate

  private let presentation = KioskPresentationController()
  private let covers = CoverWindowCoordinator()
  private let hud = KioskHUD()
  private let windowStore = CoverWindowStore()
  private let filterHolder = FilterHolder()
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "fr.camille.babywork.diagnostics",
    category: "Kiosk"
  )

  init(terminationGate: TerminationGate = TerminationGate()) {
    self.terminationGate = terminationGate
    emergency = KioskEmergencyExit(store: windowStore)
    emergency.hud = hud
    covers.store = windowStore
    covers.hud = hud
    let holder = filterHolder
    emergency.tapHandles = {
      holder.tapHandles()
    }
  }

  func capturePresentation() throws -> PresentationOptionsSnapshot {
    let snapshot = presentation.capture()
    windowStore.setCapturedPresentation(snapshot.rawValue)
    return snapshot
  }

  func createCoverWindows() throws -> [ScreenDescriptor] {
    emergency.arm()
    covers.hud = hud
    covers.store = windowStore
    let emergency = self.emergency
    let hud = self.hud
    covers.onAdultExit = { kind in
      hud.noteExit(kind)
      emergency.run(kind)
    }
    return try covers.createCoverWindows()
  }

  func applyKioskPresentation() throws {
    try presentation.applyKiosk()
    covers.refocus()
  }

  func startInputFilter() async throws {
    stopInputFilter()
    let statusHandler = onFilterStatus
    let countsHandler = onCountsChange
    let emergency = self.emergency
    let hud = self.hud

    do {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        let once = OnceResume(continuation)
        let engine = SessionInputFilter(
          onStatusChange: { status in
            switch status {
            case .active:
              once.resume(with: .success(()))
            case .failed(let reason):
              once.resume(with: .failure(KioskSessionError.filterUnavailable(reason)))
            default:
              break
            }
            statusHandler?(status)
          },
          onCountsChange: { counts in
            countsHandler?(counts)
          },
          onAdultExit: { kind in
            hud.noteExit(kind)
            emergency.run(kind)
          },
          hud: hud
        )
        filterHolder.set(engine)
        engine.start()
        Task {
          try await Task.sleep(for: .seconds(2))
          once.resume(
            with: .failure(KioskSessionError.filterUnavailable("délai de création du filtre dépassé"))
          )
        }
      }
    } catch {
      stopInputFilter()
      throw error
    }

    guard filterHolder.current()?.isTapEnabled() == true else {
      stopInputFilter()
      throw KioskSessionError.filterUnavailable("tap créé mais inactif")
    }
    logger.info("Filtre du kiosque actif")
  }

  func restorePresentation(_ snapshot: PresentationOptionsSnapshot) {
    presentation.restore(snapshot)
  }

  func closeCoverWindows() {
    covers.closeCoverWindows()
  }

  func stopInputFilter() {
    filterHolder.stop()
    onFilterStatus?(.inactive)
  }

  func reenableFilter() {
    filterHolder.current()?.reenableTapIfPossible()
  }

  func hideDiagnosticInterface() {
    onHideDiagnosticInterface?()
  }

  func revealDiagnosticInterface() {
    onRevealDiagnosticInterface?()
  }
}

/// Reprend une continuation au plus une fois, depuis n’importe quel thread.
private final class OnceResume: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Void, Error>?

  init(_ continuation: CheckedContinuation<Void, Error>) {
    self.continuation = continuation
  }

  func resume(with result: Result<Void, Error>) {
    lock.lock()
    let pending = continuation
    continuation = nil
    lock.unlock()
    pending?.resume(with: result)
  }
}
