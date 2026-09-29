import Foundation

/// Porte le filtre de session. `stop()` est appelé sur le fil principal :
/// il désactive le tap et arrête son run loop.
final class FilterHolder: @unchecked Sendable {
  private let lock = NSLock()
  private var filter: SessionInputFilter?

  func set(_ filter: SessionInputFilter?) {
    lock.lock()
    self.filter = filter
    lock.unlock()
  }

  func current() -> SessionInputFilter? {
    lock.lock()
    defer { lock.unlock() }
    return filter
  }

  func stop() {
    lock.lock()
    let current = filter
    lock.unlock()
    current?.stop()
    lock.lock()
    if filter === current {
      filter = nil
    }
    lock.unlock()
  }
}

/// Bloque `applicationShouldTerminate` tant qu’une session est en cours.
/// Lu depuis ce callback, qui n’est pas isolé sur le MainActor.
final class TerminationGate: @unchecked Sendable {
  private let lock = NSLock()
  private var blocked = false

  func setBlocked(_ blocked: Bool) {
    lock.lock()
    self.blocked = blocked
    lock.unlock()
  }

  func isBlocked() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return blocked
  }
}
