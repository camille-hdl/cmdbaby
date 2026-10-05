import Foundation

/// Palette, typographie et lueur du mode Terminal.
/// Les composantes sont sRGB, dans [0, 1]. Le kit n’importe pas AppKit.
public enum TerminalStyle: Sendable {
  public struct SRGB: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
  }

  /// Fond `#0D0208`.
  public static let background = SRGB(red: 13.0 / 255.0, green: 2.0 / 255.0, blue: 8.0 / 255.0)
  /// Glyphe de traîne `#00FF41`.
  public static let trail = SRGB(red: 0, green: 1, blue: 65.0 / 255.0)
  /// Traîne en fin de vie `#008F11`, avant le transparent.
  public static let trailEnd = SRGB(red: 0, green: 143.0 / 255.0, blue: 17.0 / 255.0)
  /// Glyphe de tête `#D7FFD9`.
  public static let head = SRGB(red: 215.0 / 255.0, green: 1, blue: 217.0 / 255.0)
  /// Lueur de la tête `#A8FFB0`.
  public static let headGlow = SRGB(red: 168.0 / 255.0, green: 1, blue: 176.0 / 255.0)
  /// Texte du prompt `#00FF41`.
  public static let prompt = SRGB(red: 0, green: 1, blue: 65.0 / 255.0)

  public static let promptFontNames = ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"]
  public static let promptFontSize: Double = 64
  public static let glowBlur: Double = 6
  public static let headGlowBlur: Double = 10

  /// Hauteur d’une cellule de pluie, en points.
  public static let cellHeight: Double = 28
  /// Largeur d’une cellule de pluie, en points (0,6 × hauteur, arrondi).
  public static let cellWidth: Double = 17

  /// `false` retire lignes de balayage, vignettage et coins arrondis.
  public static let crtEffectEnabled = true
  /// Une ligne sombre d’un pixel physique tous les `scanlinePeriodPixels` pixels.
  public static let scanlinePeriodPixels = 3
  public static let scanlineOpacity = 0.15
  /// Opacité du noir dans les coins du vignettage.
  public static let vignetteEdgeOpacity = 0.35
  /// Fraction de la demi-diagonale sous laquelle le vignettage est nul.
  public static let vignetteInnerRadius = 0.6
  /// Rayon des coins arrondis noirs, en points.
  public static let crtCornerRadius: Double = 48

  /// Bord gauche de la cellule de grille qui contient `x` (coordonnées globales).
  public static func snapToGrid(x: Double) -> Double {
    (x / cellWidth).rounded(.down) * cellWidth
  }
}
