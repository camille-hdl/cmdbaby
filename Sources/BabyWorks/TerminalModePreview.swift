import BabyWorkDiagnosticsKit
import SwiftUI

/// Aperçu statique du mode Terminal pour la carte de Réglages.
struct TerminalModePreview: View {
  var body: some View {
    Self.background
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          let scale = size.width / 240
          ZStack {
            ForEach(Array(Self.glyphs.enumerated()), id: \.offset) { _, mark in
              Text(mark.glyph)
                .font(.system(size: 13 * scale, weight: .bold, design: .monospaced))
                .foregroundStyle((mark.isHead ? Self.head : Self.trail).opacity(mark.opacity))
                .shadow(color: Self.trail, radius: 3)
                .position(x: size.width * mark.x, y: size.height * mark.y)
            }
            Text("_")
              .font(.system(size: 28 * scale, weight: .bold, design: .monospaced))
              .foregroundStyle(Self.prompt)
              .shadow(color: Self.prompt, radius: 3)
              .position(x: size.width / 2, y: size.height / 2)
            if TerminalStyle.crtEffectEnabled {
              RadialGradient(
                stops: [
                  .init(color: .black.opacity(0), location: 0),
                  .init(color: .black.opacity(0), location: TerminalStyle.vignetteInnerRadius),
                  .init(color: .black.opacity(TerminalStyle.vignetteEdgeOpacity), location: 1),
                ],
                center: .center,
                startRadius: 0,
                endRadius: hypot(size.width, size.height) / 2
              )
              .frame(width: size.width, height: size.height)
              .allowsHitTesting(false)
            }
          }
        }
      }
  }

  private static let background = Color(nsColor: TerminalStyle.background.nsColor)
  private static let trail = Color(nsColor: TerminalStyle.trail.nsColor)
  private static let head = Color(nsColor: TerminalStyle.head.nsColor)
  private static let prompt = Color(nsColor: TerminalStyle.prompt.nsColor)

  /// Six colonnes fixes. La tête est le glyphe le plus bas, en `#D7FFD9`.
  private static let glyphs: [GlyphMark] = [
    GlyphMark(glyph: "ｱ", x: 0.10, y: 0.88, opacity: 1, isHead: true),
    GlyphMark(glyph: "7", x: 0.10, y: 0.79, opacity: 0.80, isHead: false),
    GlyphMark(glyph: "ｸ", x: 0.10, y: 0.70, opacity: 0.60, isHead: false),
    GlyphMark(glyph: "ｾ", x: 0.10, y: 0.61, opacity: 0.40, isHead: false),
    GlyphMark(glyph: "ﾐ", x: 0.10, y: 0.52, opacity: 0.22, isHead: false),
    GlyphMark(glyph: "ｦ", x: 0.10, y: 0.43, opacity: 0.12, isHead: false),

    GlyphMark(glyph: "ﾎ", x: 0.26, y: 0.62, opacity: 1, isHead: true),
    GlyphMark(glyph: "3", x: 0.26, y: 0.53, opacity: 0.66, isHead: false),
    GlyphMark(glyph: "ﾅ", x: 0.26, y: 0.44, opacity: 0.33, isHead: false),
    GlyphMark(glyph: "ﾗ", x: 0.26, y: 0.35, opacity: 0.12, isHead: false),

    GlyphMark(glyph: "ｷ", x: 0.40, y: 0.94, opacity: 1, isHead: true),
    GlyphMark(glyph: "0", x: 0.40, y: 0.85, opacity: 0.84, isHead: false),
    GlyphMark(glyph: "ﾂ", x: 0.40, y: 0.76, opacity: 0.68, isHead: false),
    GlyphMark(glyph: "ﾜ", x: 0.40, y: 0.67, opacity: 0.50, isHead: false),
    GlyphMark(glyph: "ｻ", x: 0.40, y: 0.58, opacity: 0.34, isHead: false),
    GlyphMark(glyph: "ﾕ", x: 0.40, y: 0.49, opacity: 0.18, isHead: false),
    GlyphMark(glyph: "ﾆ", x: 0.40, y: 0.40, opacity: 0.12, isHead: false),

    GlyphMark(glyph: "ﾏ", x: 0.58, y: 0.74, opacity: 1, isHead: true),
    GlyphMark(glyph: "5", x: 0.58, y: 0.65, opacity: 0.75, isHead: false),
    GlyphMark(glyph: "ｵ", x: 0.58, y: 0.56, opacity: 0.50, isHead: false),
    GlyphMark(glyph: "ﾁ", x: 0.58, y: 0.47, opacity: 0.25, isHead: false),
    GlyphMark(glyph: "ﾊ", x: 0.58, y: 0.38, opacity: 0.12, isHead: false),

    GlyphMark(glyph: "ﾘ", x: 0.74, y: 0.56, opacity: 1, isHead: true),
    GlyphMark(glyph: "9", x: 0.74, y: 0.47, opacity: 0.50, isHead: false),
    GlyphMark(glyph: "ﾓ", x: 0.74, y: 0.38, opacity: 0.12, isHead: false),

    GlyphMark(glyph: "ﾈ", x: 0.90, y: 0.86, opacity: 1, isHead: true),
    GlyphMark(glyph: "2", x: 0.90, y: 0.77, opacity: 0.80, isHead: false),
    GlyphMark(glyph: "ﾔ", x: 0.90, y: 0.68, opacity: 0.60, isHead: false),
    GlyphMark(glyph: "ﾌ", x: 0.90, y: 0.59, opacity: 0.40, isHead: false),
    GlyphMark(glyph: "ﾄ", x: 0.90, y: 0.50, opacity: 0.22, isHead: false),
    GlyphMark(glyph: "ｺ", x: 0.90, y: 0.41, opacity: 0.12, isHead: false),
  ]
}

private struct GlyphMark {
  var glyph: String
  var x: CGFloat
  var y: CGFloat
  var opacity: Double
  var isHead: Bool
}
