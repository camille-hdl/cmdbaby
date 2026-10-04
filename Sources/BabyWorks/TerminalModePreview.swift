import BabyWorkDiagnosticsKit
import SwiftUI

/// Aperçu statique du mode Terminal pour la carte de Réglages.
struct TerminalModePreview: View {
  var body: some View {
    Color(nsColor: TerminalStyle.background.nsColor)
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          let scale = size.width / 240
          ZStack {
            ForEach(Array(Self.columns.enumerated()), id: \.offset) { _, column in
              ForEach(Array(column.glyphs.enumerated()), id: \.offset) { index, glyph in
                let isHead = index == column.glyphs.count - 1
                rainGlyph(
                  glyph,
                  isHead: isHead,
                  opacity: Self.opacity(index: index, count: column.glyphs.count),
                  size: 13 * scale,
                  x: column.x,
                  y: column.ys[index],
                  in: size
                )
              }
            }
            Text("_")
              .font(.custom("Courier-Bold", size: 22 * scale))
              .foregroundStyle(Color(nsColor: TerminalStyle.prompt.nsColor))
              .shadow(color: Color(nsColor: TerminalStyle.prompt.nsColor), radius: 3)
              .position(x: size.width * 0.5, y: size.height * 0.5)
          }
        }
      }
  }

  private func rainGlyph(
    _ text: String,
    isHead: Bool,
    opacity: Double,
    size: CGFloat,
    x: CGFloat,
    y: CGFloat,
    in bounds: CGSize
  ) -> some View {
    let color = isHead ? TerminalStyle.head : TerminalStyle.trail
    return Text(text)
      .font(.custom("HiraginoSans-W3", size: size))
      .foregroundStyle(Color(nsColor: color.nsColor).opacity(opacity))
      .shadow(color: Color(nsColor: color.nsColor), radius: 3)
      .position(x: bounds.width * x, y: bounds.height * y)
  }

  /// Opacité décroissante vers le haut : la tête (dernier glyphe) reste opaque.
  private static func opacity(index: Int, count: Int) -> Double {
    let steps = max(count, 1)
    return Double(index + 1) / Double(steps)
  }

  /// Six colonnes fixes, tête en bas. Positions prévues pour une largeur de 240 pt.
  private static let columns: [RainColumn] = [
    RainColumn(x: 0.10, glyphs: ["ｱ", "7", ":", "ﾑ"], ys: [0.18, 0.36, 0.54, 0.72]),
    RainColumn(x: 0.26, glyphs: ["8", "ﾋ", "=", "2"], ys: [0.14, 0.32, 0.50, 0.68]),
    RainColumn(x: 0.42, glyphs: ["ｿ", "0", "ｶ", "¦"], ys: [0.22, 0.40, 0.58, 0.76]),
    RainColumn(x: 0.58, glyphs: ["3", "ﾔ", "*", "9"], ys: [0.16, 0.34, 0.52, 0.70]),
    RainColumn(x: 0.74, glyphs: ["ﾄ", ".", "5", "ﾜ"], ys: [0.20, 0.38, 0.56, 0.74]),
    RainColumn(x: 0.90, glyphs: ["+", "ﾈ", "1", "ﾗ"], ys: [0.12, 0.30, 0.48, 0.66]),
  ]
}

private struct RainColumn {
  var x: CGFloat
  var glyphs: [String]
  var ys: [CGFloat]
}
