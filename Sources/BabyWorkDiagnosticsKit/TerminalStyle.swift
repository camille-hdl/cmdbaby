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
  /// Texte du prompt `#00FF41`.
  public static let prompt = SRGB(red: 0, green: 1, blue: 65.0 / 255.0)

  public static let promptFontNames = ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"]
  public static let promptFontSize: Double = 64
  public static let glowBlur: Double = 6
  public static let headGlowBlur: Double = 10
}
