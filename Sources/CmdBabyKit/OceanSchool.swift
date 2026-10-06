import CoreGraphics

public struct OceanFish: Equatable, Sendable {
  public let id: UInt64
  public var x: Double
  public var y: Double
  public var speed: Double
  public var kind: OceanFishKind
  public var displaySize: Double
  public let screenIndex: Int

  public init(
    id: UInt64,
    x: Double,
    y: Double,
    speed: Double,
    kind: OceanFishKind,
    displaySize: Double,
    screenIndex: Int
  ) {
    self.id = id
    self.x = x
    self.y = y
    self.speed = speed
    self.kind = kind
    self.displaySize = displaySize
    self.screenIndex = screenIndex
  }
}

public enum OceanFishKind: String, CaseIterable, Equatable, Sendable {
  case blue, green, orange, pink, red, brown, grey
}

public struct OceanTick: Equatable, Sendable {
  public var fish: [OceanFish]
  public var removedIDs: [UInt64]

  public init(fish: [OceanFish], removedIDs: [UInt64]) {
    self.fish = fish
    self.removedIDs = removedIDs
  }
}

/// État pur des poissons de toute la session : spawn, nage, surpopulation, cull.
public struct OceanSchool: Equatable, Sendable {
  public static let maxFish = 100
  public static let swimMin = 28.0
  public static let swimMax = 52.0
  public static let exitSpeed = 240.0
  public static let padding = 90.0

  public private(set) var fish: [OceanFish]
  private var nextBirthIndex: UInt64

  public var count: Int { fish.count }

  public init(fish: [OceanFish] = []) {
    self.fish = fish
    self.nextBirthIndex = (fish.map(\.id).max() ?? 0) + 1
  }

  /// Écran débranché en cours de session : ses poissons ne sont plus dessinés nulle part.
  public mutating func removeFish(onScreen screenIndex: Int) {
    fish.removeAll { $0.screenIndex == screenIndex }
  }

  /// Un poisson dans la moitié gauche de `screenIndex`. `rng` décide kind, x, y, speed, displaySize.
  public mutating func spawnFish<R: RandomNumberGenerator>(
    screenIndex: Int,
    screenSize: CGSize,
    groundTop: Double,
    displaySizeRange: ClosedRange<Double>,
    rng: inout R
  ) -> OceanFish {
    let kinds = OceanFishKind.allCases
    let kind = kinds[Int.random(in: 0..<kinds.count, using: &rng)]
    let displaySize = Double.random(in: displaySizeRange, using: &rng)
    let width = Double(screenSize.width)
    let height = Double(screenSize.height)

    let spawnMaxX = width / 2
    let xDraw: Double
    if Self.padding <= spawnMaxX {
      xDraw = Double.random(in: Self.padding...spawnMaxX, using: &rng)
    } else {
      xDraw = Double.random(in: 0...max(width, 1), using: &rng)
    }

    let waterLow = groundTop + displaySize / 2
    let waterHigh = height - Self.padding
    let yDraw: Double
    if waterLow <= waterHigh {
      yDraw = Double.random(in: waterLow...waterHigh, using: &rng)
    } else {
      yDraw = Double.random(in: 0...max(height, 1), using: &rng)
    }

    let speed = Double.random(in: Self.swimMin...Self.swimMax, using: &rng)

    let waterColumnValid = waterLow <= waterHigh
    let fish = OceanFish(
      id: nextBirthIndex,
      x: waterColumnValid ? xDraw : width / 4,
      y: waterColumnValid ? yDraw : height / 2,
      speed: speed,
      kind: kind,
      displaySize: displaySize,
      screenIndex: screenIndex
    )
    nextBirthIndex += 1
    self.fish.append(fish)
    applyOverpopulationBoost()
    return fish
  }

  /// Avance tous les poissons. Applique exitSpeed aux trop vieux si count > maxFish.
  /// Retire ceux dont `x > width + displaySize/2`.
  public mutating func tick(dt: Double, screenWidths: [Double]) -> OceanTick {
    applyOverpopulationBoost()
    for index in fish.indices {
      fish[index].x += fish[index].speed * dt
    }

    var removedIDs: [UInt64] = []
    fish.removeAll { candidate in
      let shouldRemove: Bool
      if candidate.screenIndex < 0 || candidate.screenIndex >= screenWidths.count {
        shouldRemove = true
      } else {
        let width = screenWidths[candidate.screenIndex]
        shouldRemove = candidate.x > width + candidate.displaySize / 2
      }
      if shouldRemove {
        removedIDs.append(candidate.id)
      }
      return shouldRemove
    }

    return OceanTick(fish: fish, removedIDs: removedIDs)
  }

  private mutating func applyOverpopulationBoost() {
    let overflow = fish.count - Self.maxFish
    guard overflow > 0 else { return }
    let oldestIDs = Set(fish.map(\.id).sorted().prefix(overflow))
    for index in fish.indices where oldestIDs.contains(fish[index].id) {
      fish[index].speed = Self.exitSpeed
    }
  }
}
