import AppKit
import CmdBabyKit
import Foundation

/// Pont AppKit pour le contrôleur de kiosque : écrans vivants, présentation, filtre.
@MainActor
final class AppKitKioskEnvironment: KioskSessionServices {
  var onFilterStatus: (@Sendable (InputFilterStatus) -> Void)?
  var onCountsChange: (@Sendable ([MonitoredShortcut: Int]) -> Void)?
  var onHideDiagnosticInterface: (() -> Void)?
  var onAdultExit: (@Sendable (AdultExitKind) -> Void)?

  private let presentation = KioskPresentationController()
  private let covers = CoverWindowCoordinator()
  private let filterHolder = FilterHolder()
  private lazy var watchdog = SessionWatchdog(
    filter: { [filterHolder] in filterHolder.current() },
    covers: covers
  )
  private var sessionExits = AdultExitSettings()

  func prepareSession(_ configuration: CmdBabyConfiguration) {
    sessionExits = configuration.exits
    covers.prepare(mode: configuration.mode, exits: configuration.exits)
  }

  func capturePresentation() throws -> PresentationOptionsSnapshot {
    presentation.capture()
  }

  func createCoverWindows() throws -> [ScreenDescriptor] {
    let onAdultExit = self.onAdultExit
    covers.onAdultExit = { kind in
      onAdultExit?(kind)
    }
    return try covers.createCoverWindows()
  }

  func applyKioskPresentation() async throws {
    try presentation.applyKiosk()
    // Le tap reste armé jusqu’à la sortie : on ne touche pas au filtre ici.
    await covers.ensurePrimaryCoverIsKey()
    watchdog.start()
  }

  func startInputFilter() async throws {
    stopInputFilter()
    let statusHandler = onFilterStatus
    let countsHandler = onCountsChange
    let exitHandler = onAdultExit

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
            exitHandler?(kind)
          },
          exits: sessionExits
        )
        filterHolder.set(engine)
        engine.start()
        Task {
          try await Task.sleep(for: .seconds(2))
          let timedOut = once.resume(
            with: .failure(KioskSessionError.filterUnavailable("délai de création du filtre dépassé"))
          )
          if timedOut {
            LifecycleLogRecorder.shared.emit(.tapFail(reason: "deadline"))
          }
        }
      }
    } catch {
      stopInputFilter()
      throw error
    }

    guard filterHolder.current()?.isTapEnabled() == true else {
      stopInputFilter()
      LifecycleLogRecorder.shared.emit(.tapFail(reason: "inactive"))
      throw KioskSessionError.filterUnavailable("tap créé mais inactif")
    }
  }

  func restorePresentation(_ snapshot: PresentationOptionsSnapshot) {
    presentation.restore(snapshot)
  }

  func closeCoverWindows() {
    covers.closeCoverWindows()
  }

  func stopInputFilter() {
    watchdog.stop()
    filterHolder.stop()
    onFilterStatus?(.inactive)
  }

  func reenableFilter() {
    filterHolder.current()?.reenableTapIfPossible()
  }

  func hideDiagnosticInterface() {
    onHideDiagnosticInterface?()
  }
}

/// Reprend une continuation au plus une fois, depuis n’importe quel thread.
private final class OnceResume: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Void, Error>?

  init(_ continuation: CheckedContinuation<Void, Error>) {
    self.continuation = continuation
  }

  @discardableResult
  func resume(with result: Result<Void, Error>) -> Bool {
    lock.lock()
    let pending = continuation
    continuation = nil
    lock.unlock()
    guard let pending else { return false }
    pending.resume(with: result)
    return true
  }
}
