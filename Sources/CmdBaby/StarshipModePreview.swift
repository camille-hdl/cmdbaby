import CmdBabyKit
import SwiftUI

/// Aperçu statique du mode Vaisseau pour la carte de Réglages.
struct StarshipModePreview: View {
  var body: some View {
    Color(nsColor: StarshipStageView.backgroundColor)
      .playModePreviewFrame {
        GeometryReader { geo in
          let size = geo.size
          let ship = shipFraction(in: size)
          ZStack {
            skybox(in: size)
            sprite("planet-09", x: 0.16, y: 0.20, widthFraction: 0.52, in: size)
              .opacity(StarshipTuning.standard.scenery(for: .planet).opacity)
            sprite("playerShip1_blue", x: ship.x, y: ship.y, widthFraction: 0.14, in: size)
            sprite(
              "laserBlue01",
              x: ship.x,
              y: ship.y - 0.20,
              widthFraction: 0.015,
              heightFraction: 0.22,
              in: size
            )
            sprite("enemyRed1", x: 0.78, y: 0.30, widthFraction: 0.12, in: size)
            sprite("meteorBrown_big1", x: 0.20, y: 0.24, widthFraction: 0.12, in: size)
            sprite("ufoGreen", x: 0.46, y: 0.14, widthFraction: 0.11, in: size)
            glyph("B", x: 0.78, y: 0.30, in: size)
            glyph("A", x: 0.20, y: 0.24, in: size)
            glyph("7", x: 0.46, y: 0.14, in: size)
          }
        }
      }
  }

  /// Centre du vaisseau en fractions du cadre. SwiftUI compte depuis le haut, le Kit depuis le bas.
  private func shipFraction(in size: CGSize) -> CGPoint {
    guard size.width > 0, size.height > 0 else {
      return CGPoint(x: 0.5, y: CGFloat(1 - StarshipTuning.standard.shipCenterFromBottom))
    }
    let center = StarshipShip.center(
      width: Double(size.width),
      height: Double(size.height),
      fractionFromBottom: StarshipTuning.standard.shipCenterFromBottom
    )
    return CGPoint(
      x: center.x / Double(size.width),
      y: 1 - center.y / Double(size.height)
    )
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
