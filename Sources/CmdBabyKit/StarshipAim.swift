import Foundation

/// Point en coordonnées locales d’un écran (points, origine en bas à gauche).
public struct StarshipPoint: Equatable, Sendable {
  public var x: Double
  public var y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

/// Visée du vaisseau : angle d’un clic, sortie d’un tir, chemin de rotation le plus court.
public enum StarshipAim: Sendable {
  /// Angle de `origin` vers `target`, en radians, 0 = vers la droite, sens trigonométrique.
  /// `nil` si les deux points sont à moins de 1 pt l’un de l’autre (clic sur le vaisseau).
  public static func angle(from origin: StarshipPoint, to target: StarshipPoint) -> Double? {
    let dx = target.x - origin.x
    let dy = target.y - origin.y
    if dx * dx + dy * dy < 1 {
      return nil
    }
    return atan2(dy, dx)
  }

  /// Point où la demi-droite partie de `origin` dans la direction `angle`
  /// sort du rectangle `[0, width] × [0, height]`.
  public static func rayExit(
    from origin: StarshipPoint,
    angle: Double,
    width: Double,
    height: Double
  ) -> StarshipPoint {
    let dx = component(cos(angle))
    let dy = component(sin(angle))
    var best: Double?

    func consider(edge: Double, along start: Double, delta: Double) {
      guard delta != 0 else { return }
      let t = (edge - start) / delta
      guard t >= 0 else { return }
      if let best, t >= best { return }
      best = t
    }

    if dx > 0 {
      consider(edge: width, along: origin.x, delta: dx)
    } else if dx < 0 {
      consider(edge: 0, along: origin.x, delta: dx)
    }
    if dy > 0 {
      consider(edge: height, along: origin.y, delta: dy)
    } else if dy < 0 {
      consider(edge: 0, along: origin.y, delta: dy)
    }

    let t = best ?? 0
    return StarshipPoint(x: origin.x + t * dx, y: origin.y + t * dy)
  }

  /// Cible traversée par un tir parti de `origin` dans la direction `angle` :
  /// parmi les cibles devant le vaisseau (projection positive) dont le centre est à au plus
  /// `radius` de la demi-droite, la plus proche de `origin`. `nil` sinon.
  public static func firstHit(
    origin: StarshipPoint,
    angle: Double,
    candidates: [(id: Int, center: StarshipPoint)],
    radius: Double
  ) -> Int? {
    let directionX = cos(angle)
    let directionY = sin(angle)
    var closest: (id: Int, along: Double)?
    for candidate in candidates {
      let offsetX = candidate.center.x - origin.x
      let offsetY = candidate.center.y - origin.y
      let along = offsetX * directionX + offsetY * directionY
      let across = abs(offsetX * directionY - offsetY * directionX)
      guard along > 0, across <= radius else { continue }
      if let closest, along >= closest.along { continue }
      closest = (candidate.id, along)
    }
    return closest?.id
  }

  /// Angle équivalent à `target` (à 2π près) le plus proche de `current`.
  /// Sert à faire tourner le vaisseau par le chemin le plus court.
  public static func nearestEquivalent(of target: Double, to current: Double) -> Double {
    let turns = (current - target) / (2 * Double.pi)
    return target + 2 * Double.pi * turns.rounded()
  }

  /// `abs(value) < 1e-12` compte pour zéro : pas de division par un delta nul.
  private static func component(_ value: Double) -> Double {
    abs(value) < 1e-12 ? 0 : value
  }
}
