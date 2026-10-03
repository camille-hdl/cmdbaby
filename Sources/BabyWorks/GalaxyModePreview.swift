import BabyWorkDiagnosticsKit
import SwiftUI

/// Aperçu statique du mode Galaxie pour la carte de Réglages.
struct GalaxyModePreview: View {
  var body: some View {
    Color(nsColor: GalaxyBackdrop.color(at: 0))
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          let scale = size.width / 240
          ZStack {
            ForEach(Array(Self.stars.enumerated()), id: \.offset) { _, star in
              Text(WarpFieldCatalog.stars[star.symbol])
                .font(.system(size: star.size * scale))
                .position(x: size.width * star.x, y: size.height * star.y)
            }
            glyph(
              PlayGlyphResolver.glyph(fromVisibleCharacter: "a", emojiIndex: 0).displayText,
              size: 36 * scale,
              x: 0.30,
              y: 0.42,
              in: size
            )
            glyph(
              PlayGlyphResolver.glyph(fromVisibleCharacter: "b", emojiIndex: 0).displayText,
              size: 32 * scale,
              x: 0.56,
              y: 0.64,
              in: size
            )
            glyph(
              PlayGlyphResolver.emojis[4],
              size: 28 * scale,
              x: 0.74,
              y: 0.32,
              in: size
            )
          }
        }
      }
  }

  private func glyph(_ text: String, size: CGFloat, x: CGFloat, y: CGFloat, in bounds: CGSize) -> some View {
    Text(text)
      .font(.system(size: size, weight: .bold))
      .foregroundStyle(Color(nsColor: .white))
      .position(x: bounds.width * x, y: bounds.height * y)
  }

  /// Positions fixes, tailles prévues pour une largeur de 240 pt.
  private static let stars: [StarMark] = [
    StarMark(x: 0.08, y: 0.16, size: 9, symbol: 0),
    StarMark(x: 0.16, y: 0.78, size: 13, symbol: 1),
    StarMark(x: 0.12, y: 0.46, size: 7, symbol: 2),
    StarMark(x: 0.28, y: 0.12, size: 15, symbol: 3),
    StarMark(x: 0.40, y: 0.22, size: 8, symbol: 0),
    StarMark(x: 0.36, y: 0.84, size: 11, symbol: 1),
    StarMark(x: 0.50, y: 0.14, size: 10, symbol: 2),
    StarMark(x: 0.62, y: 0.20, size: 16, symbol: 3),
    StarMark(x: 0.84, y: 0.16, size: 8, symbol: 0),
    StarMark(x: 0.90, y: 0.40, size: 12, symbol: 1),
    StarMark(x: 0.86, y: 0.72, size: 14, symbol: 2),
    StarMark(x: 0.68, y: 0.86, size: 9, symbol: 3),
    StarMark(x: 0.22, y: 0.62, size: 8, symbol: 1),
    StarMark(x: 0.48, y: 0.48, size: 11, symbol: 2),
    StarMark(x: 0.78, y: 0.52, size: 7, symbol: 0),
  ]
}

private struct StarMark {
  var x: CGFloat
  var y: CGFloat
  var size: CGFloat
  var symbol: Int
}
