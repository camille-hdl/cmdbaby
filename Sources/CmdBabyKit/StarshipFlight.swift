import Foundation

/// Trajectoire d’une cible vers le centre du vaisseau, en accélérant jusqu’à un plafond.
public struct StarshipFlight: Equatable, Sendable {
  public let start: StarshipPoint
  public let goal: StarshipPoint
  public let initialSpeed: Double
  public let acceleration: Double
  public let maxSpeed: Double

  public init(
    start: StarshipPoint,
    goal: StarshipPoint,
    initialSpeed: Double,
    acceleration: Double,
    maxSpeed: Double
  ) {
    self.start = start
    self.goal = goal
    self.initialSpeed = initialSpeed
    self.acceleration = acceleration
    self.maxSpeed = maxSpeed
  }

  /// Tire `initialSpeed` dans `tuning.initialSpeedRange` et `acceleration` dans `tuning.accelerationRange`
  /// (interpolation linéaire, `roll` dans `[0, 1)`), `maxSpeed = tuning.maxSpeed`.
  public static func random(
    start: StarshipPoint,
    goal: StarshipPoint,
    tuning: StarshipTuning,
    speedRoll: Double,
    accelerationRoll: Double
  ) -> StarshipFlight {
    StarshipFlight(
      start: start,
      goal: goal,
      initialSpeed: interpolate(tuning.initialSpeedRange, roll: speedRoll),
      acceleration: interpolate(tuning.accelerationRange, roll: accelerationRoll),
      maxSpeed: tuning.maxSpeed
    )
  }

  public var totalDistance: Double {
    hypot(goal.x - start.x, goal.y - start.y)
  }

  /// Distance parcourue après `elapsed` secondes (0 si `elapsed ≤ 0`), sans limite à `totalDistance`.
  public func distance(at elapsed: Double) -> Double {
    guard elapsed > 0 else { return 0 }
    let coast = coastTime
    if elapsed <= coast {
      return initialSpeed * elapsed + acceleration * elapsed * elapsed / 2
    }
    let coasted = initialSpeed * coast + acceleration * coast * coast / 2
    return coasted + maxSpeed * (elapsed - coast)
  }

  /// Position après `elapsed` secondes ; ne dépasse jamais `goal`.
  public func position(at elapsed: Double) -> StarshipPoint {
    let total = totalDistance
    guard total > 0 else { return goal }
    let traveled = min(distance(at: elapsed), total)
    let fraction = traveled / total
    return StarshipPoint(
      x: start.x + (goal.x - start.x) * fraction,
      y: start.y + (goal.y - start.y) * fraction
    )
  }

  /// Distance restante jusqu’au centre du vaisseau (jamais négative).
  public func remaining(at elapsed: Double) -> Double {
    max(0, totalDistance - distance(at: elapsed))
  }

  /// Temps pour parcourir `distance` points depuis le départ (inverse de `distance(at:)`). 0 si `distance ≤ 0`.
  public func time(toTravel distance: Double) -> Double {
    guard distance > 0 else { return 0 }
    let coast = coastTime
    if coast.isInfinite {
      return distance / initialSpeed
    }
    let coasted = self.distance(at: coast)
    if distance <= coasted {
      let discriminant = initialSpeed * initialSpeed + 2 * acceleration * distance
      return (-initialSpeed + discriminant.squareRoot()) / acceleration
    }
    return coast + (distance - coasted) / maxSpeed
  }

  /// Angle de la trajectoire (de `start` vers `goal`), comme `StarshipAim.angle`.
  public var heading: Double {
    StarshipAim.angle(from: start, to: goal) ?? 0
  }

  /// Instant où la vitesse atteint `maxSpeed`. Zéro si elle y est déjà.
  /// Accélération nulle : on reste à `initialSpeed`, sauf si elle dépasse déjà le plafond.
  private var coastTime: Double {
    if acceleration == 0 {
      return initialSpeed >= maxSpeed ? 0 : .infinity
    }
    return max(0, (maxSpeed - initialSpeed) / acceleration)
  }

  private static func interpolate(_ range: ClosedRange<Double>, roll: Double) -> Double {
    let clamped = min(max(roll, 0), 0.999_999)
    return range.lowerBound + clamped * (range.upperBound - range.lowerBound)
  }
}
