import Foundation

/// Rectangle en unités d’image : 0…1 sur chaque axe, origine en bas à gauche de l’image.
public struct StarshipUnitRect: Equatable, Sendable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
}

/// Découpe une skybox en aspect-fill sur l’union des écrans.
public enum StarshipSkyboxFraming: Sendable {
  /// Rapport largeur / hauteur des skyboxes Kenney (4096 × 2048).
  public static let imageAspect: Double = 2

  /// Morceau d’image à afficher sur l’écran `index`.
  /// `nil` si `index` n’est pas dans `screens` ou si l’union est vide (largeur ou hauteur ≤ 0).
  public static func contentsRect(
    forScreen index: Int,
    among screens: [TerminalScreen],
    imageAspect: Double = imageAspect
  ) -> StarshipUnitRect? {
    guard let screen = screens.first(where: { $0.index == index }),
      let minX = screens.map(\.x).min(),
      let minY = screens.map(\.y).min(),
      let maxX = screens.map({ $0.x + $0.width }).max(),
      let maxY = screens.map({ $0.y + $0.height }).max()
    else { return nil }
    let unionWidth = maxX - minX
    let unionHeight = maxY - minY
    guard unionWidth > 0, unionHeight > 0 else { return nil }

    let visibleX: Double
    let visibleY: Double
    let visibleWidth: Double
    let visibleHeight: Double
    if unionWidth / unionHeight > imageAspect {
      visibleX = 0
      visibleWidth = 1
      visibleHeight = unionHeight / (unionWidth / imageAspect)
      visibleY = (1 - visibleHeight) / 2
    } else {
      visibleY = 0
      visibleHeight = 1
      visibleWidth = (unionWidth / unionHeight) / imageAspect
      visibleX = (1 - visibleWidth) / 2
    }

    return StarshipUnitRect(
      x: visibleX + (screen.x - minX) / unionWidth * visibleWidth,
      y: visibleY + (screen.y - minY) / unionHeight * visibleHeight,
      width: screen.width / unionWidth * visibleWidth,
      height: screen.height / unionHeight * visibleHeight
    )
  }
}
