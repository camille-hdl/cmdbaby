import Foundation

/// Colonne de pluie en coordonnées globales. La tête saute de cellule en cellule.
public struct TerminalRainColumn: Equatable, Sendable {
  /// Bord gauche de la cellule, aligné sur la grille globale.
  public let x: Double
  /// Haut de la première cellule.
  public let topY: Double
  /// La colonne s’arrête quand une cellule passerait sous ce y.
  public let floorY: Double
  public let stepInterval: Double
  public let trailLifetime: Double
  public private(set) var emittedCells: Int
  public private(set) var elapsed: Double

  public init(
    x: Double,
    topY: Double,
    floorY: Double,
    stepInterval: Double,
    trailLifetime: Double
  ) {
    self.x = x
    self.topY = topY
    self.floorY = floorY
    self.stepInterval = stepInterval
    self.trailLifetime = trailLifetime
    self.emittedCells = 0
    self.elapsed = 0
  }

  /// Plus aucune cellule à émettre : la suivante passerait sous `floorY`.
  public var isFinished: Bool {
    nextBottom < floorY
  }

  /// Avance le temps et renvoie les y (bas de cellule, global) des nouvelles cellules, dans l’ordre.
  public mutating func advance(by dt: Double) -> [Double] {
    guard dt > 0, stepInterval > 0 else { return [] }
    elapsed += dt
    var bottoms: [Double] = []
    while !isFinished {
      let due = Double(emittedCells + 1) * stepInterval
      if elapsed + 1e-9 < due { break }
      emittedCells += 1
      bottoms.append(topY - Double(emittedCells) * TerminalStyle.cellHeight)
    }
    return bottoms
  }

  private var nextBottom: Double {
    topY - Double(emittedCells + 1) * TerminalStyle.cellHeight
  }
}
