import Foundation

/// Coupure du tap d’un filtre, lisible depuis le callback sans hop MainActor.
/// Un par filtre : le `reset()` d’une nouvelle session ne réarme pas un ancien tap.
public final class SessionInputKillSwitch: @unchecked Sendable {
  private let lock = NSLock()
  private var engaged = false

  public init() {}

  public func reset() {
    lock.lock()
    engaged = false
    lock.unlock()
  }

  public func engage() {
    lock.lock()
    engaged = true
    lock.unlock()
  }

  public var isEngaged: Bool {
    lock.lock()
    defer { lock.unlock() }
    return engaged
  }
}
