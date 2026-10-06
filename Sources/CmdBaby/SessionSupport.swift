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
