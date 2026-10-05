import Foundation

/// Décide combien de colonnes lancer, et où, sans connaître les écrans.
public enum TerminalRainPlanner: Sendable {
  public static func columnCount(
    for request: TerminalRainRequest,
    tuning: TerminalRainTuning,
    using rng: inout some RandomNumberGenerator
  ) -> Int {
    switch request {
    case .column:
      return 1
    case .wave:
      return Int.random(in: tuning.waveColumnRange, using: &rng)
    }
  }

  /// Colonnes encore lançables sans dépasser `tuning.maxActiveColumns`.
  public static func admissibleCount(
    requested: Int,
    active: Int,
    tuning: TerminalRainTuning
  ) -> Int {
    max(0, min(requested, tuning.maxActiveColumns - active))
  }

  /// `count` bords gauches distincts, alignés sur la grille globale, dans `[minX, maxX - cellWidth]`.
  /// S’il y a moins de colonnes de grille que `count`, renvoie toutes celles qui tiennent.
  public static func distinctGridXs(
    count: Int,
    minX: Double,
    maxX: Double,
    using rng: inout some RandomNumberGenerator
  ) -> [Double] {
    guard count > 0, let slots = gridSlots(minX: minX, maxX: maxX) else { return [] }

    var remaining = slots
    let take = min(count, remaining.count)
    for index in 0..<take {
      let swap = index + Int.random(in: 0...(remaining.count - 1 - index), using: &rng)
      remaining.swapAt(index, swap)
    }
    return Array(remaining.prefix(take))
  }

  /// Bords gauches de grille dans `[minX, maxX - cellWidth]`, du plus petit au plus grand.
  private static func gridSlots(minX: Double, maxX: Double) -> [Double]? {
    let cell = TerminalStyle.cellWidth
    let upper = maxX - cell
    guard cell > 0, upper >= minX else { return nil }

    let first = Int(ceil(minX / cell))
    let last = Int(floor(upper / cell))
    guard last >= first else { return nil }
    return (first...last).map { Double($0) * cell }
  }
}
