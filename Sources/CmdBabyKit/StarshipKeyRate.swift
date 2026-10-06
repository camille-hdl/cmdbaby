import Foundation

/// Cadence de frappe sur une fenêtre glissante, en touches par minute.
public struct StarshipKeyRate: Equatable, Sendable {
  private let window: Double
  private let cap: Double
  /// Instants des touches, du plus ancien au plus récent.
  private var times: [TimeInterval] = []

  public init(window: Double, cap: Double) {
    self.window = window
    self.cap = cap
  }

  /// Une touche à l’instant `time` (secondes, horloge monotone).
  public mutating func record(at time: TimeInterval) {
    times.append(time)
    let limit = Int(cap * window / 60) + 1
    guard limit > 0, times.count > limit else { return }
    times.removeFirst(times.count - limit)
  }

  /// Touches par minute à l’instant `now`, bornées à `cap`.
  /// Une touche compte si `now - window < time ≤ now`.
  public mutating func perMinute(at now: TimeInterval) -> Double {
    forget(olderThan: now - window)
    let count = times.prefix(while: { $0 <= now }).count
    guard window > 0 else { return 0 }
    return min(cap, Double(count) * (60 / window))
  }

  private mutating func forget(olderThan oldest: TimeInterval) {
    guard let keep = times.firstIndex(where: { $0 > oldest }) else {
      times.removeAll(keepingCapacity: false)
      return
    }
    if keep > 0 {
      times.removeFirst(keep)
    }
  }
}
