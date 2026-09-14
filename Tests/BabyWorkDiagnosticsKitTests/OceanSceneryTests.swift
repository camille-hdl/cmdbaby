import CoreGraphics
import Testing

@testable import BabyWorkDiagnosticsKit

private let screen = CGSize(width: 800, height: 600)

@Test("Le sol fait 0,22 de la hauteur, terre plus sable")
func groundTopMatchesDirtAndSand() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  #expect(abs(scenery.groundTop - 0.22 * 600) < 0.5)
  #expect(scenery.dirtHeight + scenery.sandHeight == scenery.groundTop)
  #expect(abs(scenery.dirtHeight - 0.10 * 600) < 0.5)
  #expect(abs(scenery.sandHeight - 0.12 * 600) < 0.5)
}

@Test("Le sol pose de la terre et du sable, crêtes alignées")
func groundCoversDirtAndSandBands() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  let dirt = scenery.props.filter { $0.kind.assetName.hasPrefix("terrain_dirt") }
  let sand = scenery.props.filter { $0.kind.assetName.hasPrefix("terrain_sand") }
  #expect(!dirt.isEmpty)
  #expect(!sand.isEmpty)
  #expect(dirt.allSatisfy { $0.layer == .ground })
  #expect(sand.allSatisfy { $0.layer == .ground })

  let minTiles = Int((800.0 / 128.0).rounded(.up))
  let dirtTops = dirt.filter { $0.kind.assetName.hasPrefix("terrain_dirt_top") }
  let sandTops = sand.filter { $0.kind.assetName.hasPrefix("terrain_sand_top") }
  #expect(dirtTops.count >= minTiles)
  #expect(sandTops.count >= minTiles)
  #expect(dirtTops.allSatisfy { abs($0.y - (scenery.dirtHeight - 128)) < 0.5 })
  #expect(sandTops.allSatisfy { abs($0.y - (scenery.groundTop - 128)) < 0.5 })
}

@Test("La couche loin a des silhouettes dans la moitié haute de l’eau")
func farLayerPlacesBackgroundSilhouettes() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  let far = scenery.props.filter { $0.layer == .far }
  #expect((4...8).contains(far.count))
  #expect(far.allSatisfy { $0.kind.assetName.hasPrefix("background_") })
  let waterMid = (scenery.groundTop + 600) / 2
  #expect(far.allSatisfy { $0.y >= waterMid - 0.5 })
}

@Test("La couche milieu pose des props entre le sol et mi-hauteur")
func midLayerSitsAboveGround() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  let mid = scenery.props.filter { $0.layer == .mid }
  #expect((3...6).contains(mid.count))
  #expect(mid.allSatisfy { $0.y >= scenery.groundTop - 0.5 })
  #expect(mid.allSatisfy { $0.y <= 0.55 * 600 + 0.5 })
}

@Test("Le premier plan plante algues et rochers sur la crête de sable")
func foregroundIsPlantedOnSandCrest() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  let foreground = scenery.props.filter { $0.layer == .foreground }
  #expect((3...8).contains(foreground.count))
  #expect(foreground.allSatisfy { abs($0.y - scenery.groundTop) < 8 })
  #expect(
    foreground.allSatisfy {
      $0.kind.assetName.hasPrefix("seaweed_") || $0.kind.assetName.hasPrefix("rock_")
    }
  )
}

@Test("Un tour de couche loin conserve les props dans une bande finie")
func scrollWrapsWithoutLosingProps() {
  var rng = SplitMix64(seed: 1)
  var scenery = OceanScenery.generate(bounds: screen, rng: &rng)
  let count = scenery.props.count
  let period = OceanScenery.wrapPeriod(width: 800)

  scenery.scroll(cameraDelta: 800 / 0.18, bounds: screen)

  #expect(scenery.props.count == count)
  let bandMin = -OceanScenery.wrapMargin
  let bandMax = bandMin + period
  #expect(scenery.props.allSatisfy { $0.x >= bandMin && $0.x < bandMax })
}

@Test("Le sol reste collé aux bords après défilement")
func groundStillCoversTheScreenAfterScroll() {
  var rng = SplitMix64(seed: 1)
  var scenery = OceanScenery.generate(bounds: screen, rng: &rng)
  let stride = OceanScenery.tileStride

  for delta in [0.0, 40.0, 300.0, 800 / 0.72] {
    scenery.scroll(cameraDelta: delta, bounds: screen)
    let fills = scenery.props.filter {
      $0.kind.assetName.hasPrefix("terrain_sand") && !$0.kind.assetName.contains("_top_")
    }
    let xs = fills.map(\.x)
    #expect(!xs.isEmpty)
    #expect(xs.min()! <= 0)
    #expect(xs.max()! + stride >= 800)
  }
}

@Test("Les fills de sol n’utilisent pas les tuiles au coquillage")
func groundFillsOmitShellTiles() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)
  let fills = scenery.props.map(\.kind.assetName).filter {
    $0.hasPrefix("terrain_") && !$0.contains("_top_")
  }
  #expect(fills.allSatisfy { !$0.hasSuffix("_c") })
}

@Test("Après le wrap, les tuiles de sol restent collées au pas de 128")
func groundTilesStayOnStrideAfterScroll() {
  var rng = SplitMix64(seed: 1)
  var scenery = OceanScenery.generate(bounds: screen, rng: &rng)
  scenery.scroll(cameraDelta: 300, bounds: screen)

  let fills = scenery.props.filter {
    $0.kind.assetName.hasPrefix("terrain_sand") && !$0.kind.assetName.contains("_top_")
  }
  let xs = Array(Set(fills.map(\.x))).sorted()
  #expect(xs.count >= 7)
  let gaps = zip(xs, xs.dropFirst()).map { $1 - $0 }
  #expect(gaps.allSatisfy { abs($0 - OceanScenery.tileStride) < 0.01 })
}

@Test("Chaque bande de sol répète la même variante, pour un joint sans couture")
func groundRowsRepeatTheSameTile() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: screen, rng: &rng)

  func names(prefix: String, top: Bool) -> Set<String> {
    Set(
      scenery.props
        .map(\.kind.assetName)
        .filter { $0.hasPrefix(prefix) && $0.contains("_top_") == top }
    )
  }

  let sandFill = names(prefix: "terrain_sand", top: false)
  let dirtFill = names(prefix: "terrain_dirt", top: false)
  #expect(names(prefix: "terrain_sand", top: true).count == 1)
  #expect(names(prefix: "terrain_dirt", top: true).count == 1)
  #expect(sandFill.count <= 1)
  #expect(dirtFill.count <= 1)
  #expect(sandFill.count + dirtFill.count >= 1)
}

@Test("La même graine reproduit le même décor")
func sameSeedReplaysTheSameScenery() {
  var rngA = SplitMix64(seed: 42)
  var rngB = SplitMix64(seed: 42)

  let a = OceanScenery.generate(bounds: screen, rng: &rngA)
  let b = OceanScenery.generate(bounds: screen, rng: &rngB)

  #expect(a == b)
}

@Test("Deux graines différentes ne produisent pas le même décor")
func differentSeedsDiverge() {
  var rngA = SplitMix64(seed: 1)
  var rngB = SplitMix64(seed: 2)

  let a = OceanScenery.generate(bounds: screen, rng: &rngA)
  let b = OceanScenery.generate(bounds: screen, rng: &rngB)

  #expect(a != b)
}

@Test("Un écran minuscule n’a pas de props mais calcule encore le sol")
func tinyScreenKeepsGroundWithoutProps() {
  var rng = SplitMix64(seed: 1)
  let scenery = OceanScenery.generate(bounds: CGSize(width: 4, height: 100), rng: &rng)

  #expect(scenery.props.isEmpty)
  #expect(abs(scenery.groundTop - 0.22 * 100) < 0.5)
  #expect(scenery.dirtHeight + scenery.sandHeight == scenery.groundTop)
}

private struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}
