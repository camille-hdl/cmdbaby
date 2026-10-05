import Foundation

/// Écran en points, repère global AppKit (origine en bas à gauche).
public struct TerminalScreen: Equatable, Sendable {
  public var index: Int
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(index: Int, x: Double, y: Double, width: Double, height: Double) {
    self.index = index
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
}

/// Topologie des écrans pour la pluie : qui est en haut, et jusqu’où une colonne coule.
public struct TerminalScreenLayout: Equatable, Sendable {
  /// macOS aligne les écrans au point près, pas toujours exactement.
  private static let edgeTolerance: Double = 2

  private let screens: [TerminalScreen]

  public init(screens: [TerminalScreen]) {
    self.screens = screens
  }

  /// Plus grande surface `width × height` ; à égalité, le plus petit `index`.
  public static func largestScreenIndex(_ screens: [TerminalScreen]) -> Int? {
    var best: TerminalScreen?
    for screen in screens {
      guard let current = best else {
        best = screen
        continue
      }
      let area = screen.width * screen.height
      let bestArea = current.width * current.height
      if area > bestArea || (area == bestArea && screen.index < current.index) {
        best = screen
      }
    }
    return best?.index
  }

  /// Écrans sans écran au-dessus, triés par index.
  public var topScreenIndices: [Int] {
    topScreens.map(\.index).sorted()
  }

  /// Écran dont `[x, x + width)` contient `x` et dont le haut est le plus élevé.
  public func highestScreen(atX x: Double) -> TerminalScreen? {
    highest(among: screens.filter { containsHorizontally($0, x: x) })
  }

  /// Écran dont le cadre demi-ouvert contient le point. S’il y en a plusieurs, le plus haut.
  public func screen(atX x: Double, y: Double) -> TerminalScreen? {
    highest(among: screens.filter { screen in
      containsHorizontally(screen, x: x) && y >= screen.y && y < top(of: screen)
    })
  }

  /// Bas du dernier écran atteint en descendant depuis `(x, topY - 1)`.
  /// Un trou plus grand que `edgeTolerance` arrête la colonne. Sans écran de départ, renvoie `topY`.
  public func fallFloor(atX x: Double, fromTopY topY: Double) -> Double {
    guard var current = screen(atX: x, y: topY - 1) else { return topY }
    var steps = 0
    while steps < screens.count, let below = screenBelow(current, atX: x) {
      current = below
      steps += 1
    }
    return current.y
  }

  /// Une abscisse de grille par colonne, sur un écran du haut tiré au hasard.
  /// Les abscisses restent distinctes tant qu’il reste une colonne de grille libre.
  public func randomSpawnXs(
    count: Int,
    using rng: inout some RandomNumberGenerator
  ) -> [(x: Double, topY: Double)] {
    guard count > 0 else { return [] }
    let tops = topScreens
    guard !tops.isEmpty else { return [] }

    var used: Set<Double> = []
    var spawns: [(x: Double, topY: Double)] = []
    spawns.reserveCapacity(count)
    for _ in 0..<count {
      let free = slots(on: tops, excluding: used)
      let pool = free.isEmpty ? slots(on: tops, excluding: []) : free
      guard !pool.isEmpty else { break }
      let choice = pool[Int.random(in: 0..<pool.count, using: &rng)]
      let x = choice.slots[Int.random(in: 0..<choice.slots.count, using: &rng)]
      used.insert(x)
      spawns.append((x: x, topY: top(of: choice.screen)))
    }
    return spawns
  }

  private var topScreens: [TerminalScreen] {
    screens.filter { screen in
      !screens.contains { isAbove($0, screen) }
    }
  }

  /// B est au-dessus de A s’ils se chevauchent horizontalement et que le bas de B
  /// n’est pas plus bas que le haut de A, à `edgeTolerance` près.
  private func isAbove(_ upper: TerminalScreen, _ lower: TerminalScreen) -> Bool {
    guard upper.index != lower.index else { return false }
    let overlap = min(upper.x + upper.width, lower.x + lower.width) - max(upper.x, lower.x)
    return overlap > 0 && upper.y >= top(of: lower) - Self.edgeTolerance
  }

  private func top(of screen: TerminalScreen) -> Double {
    screen.y + screen.height
  }

  private func containsHorizontally(_ screen: TerminalScreen, x: Double) -> Bool {
    x >= screen.x && x < screen.x + screen.width
  }

  /// Écran qui contient `x` et dont le haut touche le bas de `current`, à la tolérance près.
  private func screenBelow(_ current: TerminalScreen, atX x: Double) -> TerminalScreen? {
    let bottom = current.y
    return highest(among: screens.filter { candidate in
      candidate.index != current.index
        && candidate.y < bottom
        && containsHorizontally(candidate, x: x)
        && abs(top(of: candidate) - bottom) <= Self.edgeTolerance
    })
  }

  /// Le plus haut écran ; à égalité, le plus petit index.
  private func highest(among candidates: [TerminalScreen]) -> TerminalScreen? {
    candidates.max { lhs, rhs in
      let lhsTop = top(of: lhs)
      let rhsTop = top(of: rhs)
      if lhsTop == rhsTop { return lhs.index > rhs.index }
      return lhsTop < rhsTop
    }
  }

  private func slots(
    on screens: [TerminalScreen],
    excluding used: Set<Double>
  ) -> [(screen: TerminalScreen, slots: [Double])] {
    screens.compactMap { screen in
      let open = TerminalRainPlanner.gridSlots(minX: screen.x, maxX: screen.x + screen.width)
        .filter { !used.contains($0) }
      guard !open.isEmpty else { return nil }
      return (screen, open)
    }
  }
}
