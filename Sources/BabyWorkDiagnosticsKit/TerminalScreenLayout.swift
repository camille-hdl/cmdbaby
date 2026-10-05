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

public enum TerminalScreenLayout {
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
}
