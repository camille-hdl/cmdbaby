import CoreGraphics

public enum OceanLayer: String, Equatable, Sendable {
  case far
  case mid
  case ground
  case foreground

  public var parallaxFactor: Double {
    switch self {
    case .far: OceanScenery.farParallaxFactor
    case .mid: OceanScenery.midParallaxFactor
    case .ground: OceanScenery.groundParallaxFactor
    case .foreground: OceanScenery.foregroundParallaxFactor
    }
  }
}

public struct OceanPropKind: Equatable, Sendable {
  public let assetName: String

  public init(assetName: String) {
    self.assetName = assetName
  }
}

public struct OceanProp: Equatable, Sendable {
  public var kind: OceanPropKind
  public var x: Double
  public var y: Double
  public var layer: OceanLayer

  public init(kind: OceanPropKind, x: Double, y: Double, layer: OceanLayer) {
    self.kind = kind
    self.x = x
    self.y = y
    self.layer = layer
  }
}

/// Placement déterministe des couches parallaxes, du sol et des props d’un écran.
public struct OceanScenery: Equatable, Sendable {
  public static let farParallaxFactor = 0.18
  public static let midParallaxFactor = 0.40
  public static let groundParallaxFactor = 0.72
  public static let foregroundParallaxFactor = 1.0
  public static let dirtHeightRatio = 0.10
  public static let sandHeightRatio = 0.12
  public static let wrapMargin = 256.0
  public static let tileStride = 128.0

  /// Période de wrap, multiple de `tileStride`, pour que les tuiles du sol restent jointives.
  public static func wrapPeriod(width: Double) -> Double {
    let minSpan = width + 2 * wrapMargin
    guard minSpan > 0 else { return 0 }
    return (minSpan / tileStride).rounded(.up) * tileStride
  }

  public var props: [OceanProp]
  public var groundTop: Double
  public var dirtHeight: Double
  public var sandHeight: Double

  public init(
    props: [OceanProp] = [],
    groundTop: Double,
    dirtHeight: Double,
    sandHeight: Double
  ) {
    self.props = props
    self.groundTop = groundTop
    self.dirtHeight = dirtHeight
    self.sandHeight = sandHeight
  }

  public static func generate<R: RandomNumberGenerator>(
    bounds: CGSize,
    rng: inout R
  ) -> OceanScenery {
    let width = Double(bounds.width)
    let height = Double(bounds.height)
    let dirtHeight = height * dirtHeightRatio
    let sandHeight = height * sandHeightRatio
    let groundTop = dirtHeight + sandHeight

    guard width >= 8, height >= 8 else {
      return OceanScenery(
        props: [],
        groundTop: groundTop,
        dirtHeight: dirtHeight,
        sandHeight: sandHeight
      )
    }

    var props: [OceanProp] = []
    props.append(contentsOf: groundTiles(width: width, dirtHeight: dirtHeight, groundTop: groundTop, rng: &rng))
    props.append(contentsOf: scatter(
      names: Catalog.far,
      layer: .far,
      countRange: 4...8,
      width: width,
      yRange: waterMid(groundTop: groundTop, height: height)...height,
      rng: &rng
    ))
    props.append(contentsOf: scatter(
      names: Catalog.mid,
      layer: .mid,
      countRange: 3...6,
      width: width,
      yRange: groundTop...(0.55 * height),
      rng: &rng
    ))
    props.append(contentsOf: scatter(
      names: Catalog.foreground,
      layer: .foreground,
      countRange: 3...8,
      width: width,
      yRange: groundTop...groundTop,
      rng: &rng
    ))

    return OceanScenery(
      props: props,
      groundTop: groundTop,
      dirtHeight: dirtHeight,
      sandHeight: sandHeight
    )
  }

  /// Décale les props de `-cameraDelta * factor(layer)` et wrap selon une période multiple du pas de tuile.
  public mutating func scroll(cameraDelta: Double, bounds: CGSize) {
    let period = Self.wrapPeriod(width: Double(bounds.width))
    guard period > 0 else { return }
    let minX = -Self.wrapMargin
    let maxX = minX + period

    for index in props.indices {
      props[index].x -= cameraDelta * props[index].layer.parallaxFactor
      while props[index].x < minX {
        props[index].x += period
      }
      while props[index].x >= maxX {
        props[index].x -= period
      }
    }
  }

  private static func groundTiles<R: RandomNumberGenerator>(
    width: Double,
    dirtHeight: Double,
    groundTop: Double,
    rng: inout R
  ) -> [OceanProp] {
    var props: [OceanProp] = []
    let start = -wrapMargin
    let end = start + wrapPeriod(width: width)
    let dirtFillName = pick(Catalog.dirtFill, rng: &rng)
    let dirtTopName = pick(Catalog.dirtTop, rng: &rng)
    let sandFillName = pick(Catalog.sandFill, rng: &rng)
    let sandTopName = pick(Catalog.sandTop, rng: &rng)
    var x = start
    while x < end - 0.5 {
      props.append(contentsOf: stackedBand(x: x, crest: groundTop, topName: sandTopName, fillName: sandFillName))
      props.append(contentsOf: stackedBand(x: x, crest: dirtHeight, topName: dirtTopName, fillName: dirtFillName))
      x += tileStride
    }
    return props
  }

  /// Tuiles 128×128 ancrées sous la crête, sans étirement vertical.
  private static func stackedBand(x: Double, crest: Double, topName: String, fillName: String) -> [OceanProp] {
    var props: [OceanProp] = [
      OceanProp(kind: OceanPropKind(assetName: topName), x: x, y: crest - tileStride, layer: .ground)
    ]
    var y = crest - 2 * tileStride
    while y + tileStride > 0 {
      props.append(OceanProp(kind: OceanPropKind(assetName: fillName), x: x, y: y, layer: .ground))
      y -= tileStride
    }
    return props
  }

  private static func scatter<R: RandomNumberGenerator>(
    names: [String],
    layer: OceanLayer,
    countRange: ClosedRange<Int>,
    width: Double,
    yRange: ClosedRange<Double>,
    rng: inout R
  ) -> [OceanProp] {
    let count = scaledCount(from: countRange, width: width, rng: &rng)
    let yLow = yRange.lowerBound
    let yHigh = max(yRange.upperBound, yLow)
    return (0..<count).map { _ in
      let y: Double
      if yLow == yHigh {
        y = yLow
      } else {
        y = Double.random(in: yLow...yHigh, using: &rng)
      }
      return OceanProp(
        kind: OceanPropKind(assetName: pick(names, rng: &rng)),
        x: Double.random(in: 0..<max(width, 1), using: &rng),
        y: y,
        layer: layer
      )
    }
  }

  private static func scaledCount<R: RandomNumberGenerator>(
    from range: ClosedRange<Int>,
    width: Double,
    rng: inout R
  ) -> Int {
    let scale = max(1, width / 800)
    let lower = max(range.lowerBound, Int((Double(range.lowerBound) * scale).rounded()))
    let upper = max(lower, Int((Double(range.upperBound) * scale).rounded()))
    return Int.random(in: lower...upper, using: &rng)
  }

  private static func pick<R: RandomNumberGenerator>(_ names: [String], rng: inout R) -> String {
    names[Int.random(in: 0..<names.count, using: &rng)]
  }

  private static func waterMid(groundTop: Double, height: Double) -> Double {
    groundTop + (height - groundTop) / 2
  }
}

private enum Catalog {
  static let dirtFill = ["terrain_dirt_a", "terrain_dirt_b", "terrain_dirt_d"]
  static let dirtTop = [
    "terrain_dirt_top_a", "terrain_dirt_top_b", "terrain_dirt_top_c", "terrain_dirt_top_d",
    "terrain_dirt_top_e", "terrain_dirt_top_f", "terrain_dirt_top_g", "terrain_dirt_top_h",
  ]
  static let sandFill = ["terrain_sand_a", "terrain_sand_b", "terrain_sand_d"]
  static let sandTop = [
    "terrain_sand_top_a", "terrain_sand_top_b", "terrain_sand_top_c", "terrain_sand_top_d",
    "terrain_sand_top_e", "terrain_sand_top_f", "terrain_sand_top_g", "terrain_sand_top_h",
  ]
  static let far = [
    "background_seaweed_a", "background_seaweed_b", "background_seaweed_c", "background_seaweed_d",
    "background_seaweed_e", "background_seaweed_f", "background_seaweed_g", "background_seaweed_h",
    "background_rock_a", "background_rock_b", "background_terrain",
  ]
  static let mid = [
    "background_seaweed_a", "background_seaweed_b", "background_seaweed_c", "background_seaweed_d",
    "background_seaweed_e", "background_seaweed_f", "background_seaweed_g", "background_seaweed_h",
    "background_rock_a", "background_rock_b",
  ]
  static let foreground = [
    "seaweed_green_a", "seaweed_green_b", "seaweed_green_c", "seaweed_green_d",
    "seaweed_grass_a", "seaweed_grass_b",
    "seaweed_orange_a", "seaweed_orange_b",
    "seaweed_pink_a", "seaweed_pink_b", "seaweed_pink_c", "seaweed_pink_d",
    "rock_a", "rock_b",
  ]
}
