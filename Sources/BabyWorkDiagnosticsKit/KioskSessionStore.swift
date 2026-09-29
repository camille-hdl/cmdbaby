import Foundation

/// État de session lisible et forçable hors MainActor.
/// Le filet de sortie adulte pose `.configuration` sans `syncModel`.
public final class KioskSessionStore: @unchecked Sendable {
  private let lock = NSLock()
  private var state = KioskSessionState()
  private var didLogSessionStop = false

  public init() {}

  public func current() -> KioskSessionState {
    lock.lock()
    defer { lock.unlock() }
    return state
  }

  public func replace(_ state: KioskSessionState) {
    lock.lock()
    self.state = state
    lock.unlock()
  }

  public func isIdle() -> Bool {
    current().phase == .configuration
  }

  public func resetSessionStopLog() {
    lock.lock()
    didLogSessionStop = false
    lock.unlock()
  }

  public func markSessionStopLogged() {
    lock.lock()
    didLogSessionStop = true
    lock.unlock()
  }

  @discardableResult
  public func forceConfiguration(
    exitKind: AdultExitKind,
    log: LifecycleLogRecorder
  ) -> KioskSessionState {
    lock.lock()
    let from = state.phase
    let shouldLogStop = !didLogSessionStop
    if shouldLogStop {
      didLogSessionStop = true
    }
    state.lastExitKind = exitKind
    let shouldLogPhase = from != .configuration
    state.phase = .configuration
    state.lastError = nil
    state.coveredScreens = []
    let result = state
    lock.unlock()
    if shouldLogStop {
      log.emit(.sessionStop(kind: .adultExit))
    }
    if shouldLogPhase {
      log.emit(.sessionPhase(from: from, to: .configuration))
    }
    return result
  }
}
