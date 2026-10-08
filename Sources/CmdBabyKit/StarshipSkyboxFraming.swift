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
/// `drift` (0…1) descend ce cadre dans une marge verticale, fraction de la hauteur de l’image.
public enum StarshipSkyboxFraming: Sendable {
  /// Rapport largeur / hauteur des skyboxes Kenney (4096 × 2048).
  public static let imageAspect: Double = 2

  /// Morceau d’image à afficher sur l’écran `index`.
  /// `nil` si `index` n’est pas dans `screens` ou si l’union est vide (largeur ou hauteur ≤ 0).
  /// Sans marge, le résultat est l’aspect-fill de l’union. Avec une marge, la dérive 0
  /// reste cet aspect-fill tant que l’image a déjà la place en dessous ; sinon le cadre
  /// se resserre juste assez pour que la dérive 1 tienne encore dans l’image.
  public static func contentsRect(
    forScreen index: Int,
    among screens: [TerminalScreen],
    imageAspect: Double = imageAspect,
    drift: Double = 0,
    verticalMargin: Double = 0
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

    let framed = driftedWindow(
      x: visibleX,
      y: visibleY,
      width: visibleWidth,
      height: visibleHeight,
      drift: drift,
      verticalMargin: verticalMargin
    )

    return StarshipUnitRect(
      x: framed.x + (screen.x - minX) / unionWidth * framed.width,
      y: framed.y + (screen.y - minY) / unionHeight * framed.height,
      width: screen.width / unionWidth * framed.width,
      height: screen.height / unionHeight * framed.height
    )
  }

  /// Fenêtre d’aspect-fill, décalée vers le bas de `drift` × marge.
  /// La marge est une fraction de la hauteur de l’image. Une marge hors de (0, 1)
  /// ne déplace rien : le cadre reste l’aspect-fill.
  private static func driftedWindow(
    x: Double,
    y: Double,
    width: Double,
    height: Double,
    drift: Double,
    verticalMargin: Double
  ) -> (x: Double, y: Double, width: Double, height: Double) {
    guard verticalMargin > 0, verticalMargin < 1, height > 0 else {
      return (x, y, width, height)
    }
    var windowX = x
    var windowWidth = width
    var windowHeight = height
    let room = 1 - verticalMargin
    if height > room {
      let scale = room / height
      windowWidth = width * scale
      windowHeight = height * scale
      windowX = x + width / 2 - windowWidth / 2
    }
    let start = min(max(y, verticalMargin), 1 - windowHeight)
    let offset = min(max(drift, 0), 1) * verticalMargin
    let driftedY = min(max(start - offset, 0), max(0, 1 - windowHeight))
    return (windowX, driftedY, windowWidth, windowHeight)
  }
}
