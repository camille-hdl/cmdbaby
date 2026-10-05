import SwiftUI

/// Aperçu statique du mode Vaisseau pour la carte de Réglages.
struct StarshipModePreview: View {
  var body: some View {
    Color(nsColor: StarshipStageView.backgroundColor)
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          ZStack {
            skybox(in: size)
            sprite("playerShip1_blue", x: 0.50, y: 0.55, widthFraction: 0.14, rotation: 45, in: size)
            sprite(
              "laserBlue01",
              x: 0.64,
              y: 0.42,
              widthFraction: 0.015,
              heightFraction: 0.22,
              rotation: 45,
              in: size
            )
            sprite("enemyRed1", x: 0.78, y: 0.28, widthFraction: 0.12, in: size)
            sprite("meteorBrown_big1", x: 0.20, y: 0.25, widthFraction: 0.12, in: size)
            sprite("ufoGreen", x: 0.22, y: 0.78, widthFraction: 0.11, in: size)
            glyph("B", x: 0.78, y: 0.28, in: size)
            glyph("A", x: 0.20, y: 0.25, in: size)
            glyph("7", x: 0.22, y: 0.78, in: size)
          }
        }
      }
  }

  private func skybox(in size: CGSize) -> some View {
    StarshipSpriteImage(name: "starship_preview_skybox", fill: true)
      .frame(width: size.width, height: size.height)
      .clipped()
  }

  private func sprite(
    _ name: String,
    x: CGFloat,
    y: CGFloat,
    widthFraction: CGFloat,
    heightFraction: CGFloat? = nil,
    rotation: Double = 0,
    in size: CGSize
  ) -> some View {
    StarshipSpriteImage(name: name, stretches: heightFraction != nil)
      .frame(
        width: size.width * widthFraction,
        height: heightFraction.map { size.height * $0 }
      )
      .rotationEffect(.degrees(rotation))
      .position(x: size.width * x, y: size.height * y)
  }

  private func glyph(_ text: String, x: CGFloat, y: CGFloat, in size: CGSize) -> some View {
    Text(text)
      .font(.system(size: size.height * 0.08, weight: .black, design: .rounded))
      .foregroundStyle(.white)
      .shadow(color: .black, radius: 2)
      .position(x: size.width * x, y: size.height * y)
  }
}

private struct StarshipSpriteImage: View {
  let name: String
  var fill = false
  /// Le rayon a une largeur et une hauteur imposées : il occupe ce cadre.
  var stretches = false

  var body: some View {
    if let image = StarshipSprite.image(named: name) {
      let picture = Image(nsImage: image)
        .resizable()
        .interpolation(.medium)
      if stretches {
        picture
      } else {
        picture
          .aspectRatio(contentMode: fill ? .fill : .fit)
          .clipped()
      }
    }
  }
}
