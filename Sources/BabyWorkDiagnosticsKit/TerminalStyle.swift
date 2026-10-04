/// Palette et constantes du mode Terminal. Valeurs sRGB, sans AppKit.
public enum TerminalStyle: Sendable {
  public struct RGB: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
      self.red = red
      self.green = green
      self.blue = blue
    }
  }

  /// Fond `#0D0208`.
  public static let background = RGB(red: 13.0 / 255.0, green: 2.0 / 255.0, blue: 8.0 / 255.0)
  /// Glyphe de traîne `#00FF41`.
  public static let trail = RGB(red: 0, green: 1, blue: 65.0 / 255.0)
  /// Traîne en fin de vie `#008F11`.
  public static let fadingTrail = RGB(red: 0, green: 143.0 / 255.0, blue: 17.0 / 255.0)
  /// Glyphe de tête `#D7FFD9`.
  public static let head = RGB(red: 215.0 / 255.0, green: 1, blue: 217.0 / 255.0)
  /// Texte du prompt `#00FF41`.
  public static let prompt = RGB(red: 0, green: 1, blue: 65.0 / 255.0)

  public static let promptFontNames = ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"]
  public static let promptFontSize: Double = 64
  public static let glowBlur: Double = 6
  public static let headGlowBlur: Double = 10
}
