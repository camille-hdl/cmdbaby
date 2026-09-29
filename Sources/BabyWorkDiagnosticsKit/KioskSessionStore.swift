import Foundation

/// État de session. Le verrou reste en place jusqu’au ticket qui le retire.
public final class KioskSessionStore: @unchecked Sendable {
  private let lock = NSLock()
  private var state = KioskSessionState()

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
}
