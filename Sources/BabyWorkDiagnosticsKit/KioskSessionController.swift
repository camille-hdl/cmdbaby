import Foundation

/// Collaborateurs système du kiosque. Les nettoyages sont idempotents et
/// relâchent la session : pas de tap, pas de couvertures, pas de ressources de mode.
@MainActor
public protocol KioskSessionServices: AnyObject {
  func capturePresentation() throws -> PresentationOptionsSnapshot
  func createCoverWindows() throws -> [ScreenDescriptor]
  func applyKioskPresentation() async throws
  func startInputFilter() async throws
  func restorePresentation(_ snapshot: PresentationOptionsSnapshot)
  func closeCoverWindows()
  func stopInputFilter()
  func hideDiagnosticInterface()
}

/// Machine à états transactionnelle du prototype de confinement.
@MainActor
public final class KioskSessionController {
  private let sessionStore = KioskSessionStore()
  public var injectedFailure: KioskPrepStep?

  public private(set) var state: KioskSessionState {
    get { sessionStore.current() }
    set { sessionStore.replace(newValue) }
  }

  private let services: any KioskSessionServices
  private let log: LifecycleLogRecorder
  private var capturedPresentation: PresentationOptionsSnapshot?

  public init(
    services: any KioskSessionServices,
    log: LifecycleLogRecorder = .shared
  ) {
    self.services = services
    self.log = log
  }

  /// Passe en `.stopping` sans démonter : ignore « Lancer session » jusqu’à `deactivate`.
  public func beginStopping(exitKind: AdultExitKind? = nil) {
    if let exitKind {
      state.lastExitKind = exitKind
    }
    switch state.phase {
    case .configuration, .failed:
      return
    case .preparing, .activating, .active, .stopping:
      setPhase(.stopping)
    }
  }

  /// Le filtre est armé **avant** les fenêtres, pour ne jamais recouvrir l’écran sans tap vivant.
  /// L’attente du filtre doit laisser tourner la boucle principale (async), jamais la bloquer.
  @discardableResult
  public func activate() async -> KioskSessionState {
    switch state.phase {
    case .configuration, .failed:
      break
    case .preparing, .activating, .active, .stopping:
      return state
    }

    let plannedFailure = injectedFailure
    state.lastError = nil
    state.lastExitKind = nil
    capturedPresentation = nil
    services.stopInputFilter()

    do {
      log.emit(.sessionStart)
      setPhase(.preparing)

      let captured = try services.capturePresentation()
      capturedPresentation = captured
      try abortIfInjected(plannedFailure, .capturePresentation)

      services.hideDiagnosticInterface()
      // Laisse AppKit retirer les observateurs SwiftUI avant couverture / présentation.
      await Task.yield()
      guard isActivationCurrent else { return state }

      setPhase(.activating)
      try await services.startInputFilter()
      guard isActivationCurrent else { return state }
      try abortIfInjected(plannedFailure, .startInputFilter)

      let screens = try services.createCoverWindows()
      guard isActivationCurrent else { return state }
      guard !screens.isEmpty else { throw KioskSessionError.noScreens }
      state.coveredScreens = screens
      try abortIfInjected(plannedFailure, .prepareWindows)

      try await services.applyKioskPresentation()
      guard isActivationCurrent else { return state }
      try abortIfInjected(plannedFailure, .applyPresentation)

      setPhase(.active)
      state.lastError = nil
      return state
    } catch let error as KioskSessionError {
      return rollback(error)
    } catch {
      return rollback(.filterUnavailable(error.localizedDescription))
    }
  }

  @discardableResult
  public func deactivate(_ request: KioskEndRequest) -> KioskSessionState {
    if case .adultExit(let kind) = request {
      state.lastExitKind = kind
    }
    let shouldQuit = request.terminatesProcess
    let stopKind: LifecycleLog.SessionStopKind = shouldQuit ? .explicitQuit : .adultExit

    switch state.phase {
    case .configuration:
      log.emit(.sessionStop(kind: stopKind))
      if shouldQuit {
        logTeardown(shouldQuit: true, coverCount: 0)
      }
    case .failed, .preparing, .activating, .active, .stopping:
      setPhase(.stopping)
      let coverCount = state.coveredScreens.count
      logTeardown(shouldQuit: shouldQuit, coverCount: coverCount) {
        tearDown()
      }
      log.emit(.sessionStop(kind: stopKind))
    }
    setPhase(.configuration)
    state.lastError = nil
    return state
  }

  private func abortIfInjected(_ planned: KioskPrepStep?, _ step: KioskPrepStep) throws {
    if planned == step {
      throw KioskSessionError.injectedFailure(step)
    }
  }

  private var isActivationCurrent: Bool {
    switch state.phase {
    case .preparing, .activating:
      true
    case .configuration, .active, .stopping, .failed:
      false
    }
  }

  private func rollback(_ error: KioskSessionError) -> KioskSessionState {
    tearDown()
    setPhase(.failed)
    state.lastError = error
    return state
  }

  private func tearDown() {
    services.stopInputFilter()
    if let capturedPresentation {
      services.restorePresentation(capturedPresentation)
    }
    services.closeCoverWindows()
    state.coveredScreens = []
    capturedPresentation = nil
  }

  private func logTeardown(
    shouldQuit: Bool,
    coverCount: Int,
    body: () -> Void = {}
  ) {
    log.emit(
      .teardownBegin(shouldQuit: shouldQuit, coverCount: coverCount, caller: .swift)
    )
    body()
    log.emit(
      .teardownDone(shouldQuit: shouldQuit, coverCount: coverCount, caller: .swift)
    )
  }

  private func setPhase(_ phase: KioskSessionPhase) {
    let from = state.phase
    state.phase = phase
    guard from != phase else { return }
    log.emit(.sessionPhase(from: from, to: phase))
  }
}
