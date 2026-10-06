import SwiftUI

/// Aperçu statique du mode Océan pour la carte de Réglages.
struct OceanModePreview: View {
  var body: some View {
    Color(nsColor: OceanStageView.waterColor)
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          ZStack {
            sprite("background_terrain", x: 0.50, y: 0.72, widthFraction: 1.08, heightFraction: 0.28, in: size, fill: true)
            sandBand(in: size)
            sprite("seaweed_green_a", x: 0.16, y: 0.72, widthFraction: 0.15, heightFraction: 0.36, in: size)
            sprite("seaweed_pink_b", x: 0.38, y: 0.74, widthFraction: 0.13, heightFraction: 0.32, in: size)
            sprite("rock_a", x: 0.78, y: 0.78, widthFraction: 0.18, heightFraction: 0.24, in: size)
            sprite("fish_orange", x: 0.26, y: 0.28, widthFraction: 0.22, heightFraction: 0.20, in: size)
            sprite("fish_blue", x: 0.68, y: 0.40, widthFraction: 0.20, heightFraction: 0.18, in: size, flip: true)
            sprite("fish_pink", x: 0.46, y: 0.54, widthFraction: 0.18, heightFraction: 0.16, in: size)
            sprite("bubble_a", x: 0.18, y: 0.16, widthFraction: 0.09, heightFraction: 0.14, in: size)
            sprite("bubble_b", x: 0.52, y: 0.20, widthFraction: 0.07, heightFraction: 0.11, in: size)
            sprite("bubble_c", x: 0.84, y: 0.30, widthFraction: 0.08, heightFraction: 0.12, in: size)
          }
        }
      }
  }

  /// Bande de sable : tuiles `terrain_sand` sous une crête `terrain_sand_top`.
  private func sandBand(in size: CGSize) -> some View {
    let tiles = 4
    return ZStack {
      ForEach(0..<tiles, id: \.self) { index in
        let x = (CGFloat(index) + 0.5) / CGFloat(tiles)
        sprite("terrain_sand_a", x: x, y: 0.94, widthFraction: 0.30, heightFraction: 0.22, in: size, fill: true)
        sprite("terrain_sand_top_a", x: x, y: 0.82, widthFraction: 0.30, heightFraction: 0.16, in: size, fill: true)
      }
    }
  }

  private func sprite(
    _ name: String,
    x: CGFloat,
    y: CGFloat,
    widthFraction: CGFloat,
    heightFraction: CGFloat,
    in size: CGSize,
    fill: Bool = false,
    flip: Bool = false
  ) -> some View {
    OceanSpriteImage(name: name, fill: fill)
      .frame(width: size.width * widthFraction, height: size.height * heightFraction)
      .scaleEffect(x: flip ? -1 : 1, y: 1)
      .position(x: size.width * x, y: size.height * y)
  }
}

private struct OceanSpriteImage: View {
  let name: String
  var fill = false

  var body: some View {
    if let image = OceanSprite.image(named: name) {
      Image(nsImage: image)
        .resizable()
        .interpolation(.medium)
        .aspectRatio(contentMode: fill ? .fill : .fit)
        .clipped()
    }
  }
}
