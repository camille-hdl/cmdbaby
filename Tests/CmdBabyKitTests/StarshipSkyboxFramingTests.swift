import Testing

@testable import CmdBabyKit

@Test("Un écran 1440 × 900 cadre le ciel en (0,1, 0, 0,8, 1)")
func skyboxFramingCropsTheSidesOfALaptopScreen() {
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0,
      among: [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
    ),
    x: 0.1, y: 0, width: 0.8, height: 1
  )
  #expect(StarshipSkyboxFraming.imageAspect == 2)
}

@Test("Un écran au rapport de l’image montre l’image entière")
func skyboxFramingShowsTheWholeImageWhenAspectsMatch() {
  let rect = StarshipSkyboxFraming.contentsRect(
    forScreen: 0,
    among: [TerminalScreen(index: 0, x: 0, y: 0, width: 2048, height: 1024)]
  )
  expectUnit(rect, x: 0, y: 0, width: 1, height: 1)
}

@Test("Deux écrans côte à côte se partagent le ciel, rogné en haut et en bas")
func skyboxFramingSplitsASideBySidePairVertically() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1440, height: 900),
  ]
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 0, among: screens),
    x: 0, y: 0.1875, width: 0.5, height: 0.625
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 1, among: screens),
    x: 0.5, y: 0.1875, width: 0.5, height: 0.625
  )
}

@Test("Deux écrans empilés se partagent le ciel, rogné à gauche et à droite")
func skyboxFramingSplitsAStackedPairHorizontally() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 240, y: 1080, width: 1440, height: 900),
  ]
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 0, among: screens),
    x: 0.257576, y: 0, width: 0.484848, height: 0.545455
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 1, among: screens),
    x: 0.318182, y: 0.545455, width: 0.363636, height: 0.454545
  )
}

@Test("Un écran à gauche, en x négatifs, reste dans le même ciel")
func skyboxFramingPlacesAScreenWithNegativeX() {
  let screens = [
    TerminalScreen(index: 0, x: -1920, y: 200, width: 1920, height: 1080),
    TerminalScreen(index: 1, x: 0, y: 0, width: 1440, height: 900),
  ]
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 0, among: screens),
    x: 0, y: 0.238095, width: 0.571429, height: 0.642857
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(forScreen: 1, among: screens),
    x: 0.571429, y: 0.119048, width: 0.428571, height: 0.535714
  )
}

@Test("Un index absent ou une liste vide ne cadrent rien")
func skyboxFramingReturnsNilWithoutAScreen() {
  let screens = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
  #expect(StarshipSkyboxFraming.contentsRect(forScreen: 4, among: screens) == nil)
  #expect(StarshipSkyboxFraming.contentsRect(forScreen: 0, among: []) == nil)
}

@Test("Une union vide ne cadre rien")
func skyboxFramingReturnsNilWhenTheUnionIsEmpty() {
  let flat = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 0)]
  #expect(StarshipSkyboxFraming.contentsRect(forScreen: 0, among: flat) == nil)
}

@Test("Les morceaux de deux écrans côte à côte se touchent sans trou")
func skyboxFramingMakesNeighborsMeet() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1440, height: 900),
  ]
  let left = StarshipSkyboxFraming.contentsRect(forScreen: 0, among: screens)
  let right = StarshipSkyboxFraming.contentsRect(forScreen: 1, among: screens)
  #expect(left != nil)
  #expect(right != nil)
  #expect(abs((left?.x ?? 0) + (left?.width ?? 0) - (right?.x ?? 1)) < 1e-5)
  #expect(abs((left?.y ?? 0) - (right?.y ?? 1)) < 1e-5)
  #expect(abs((left?.height ?? 0) - (right?.height ?? 1)) < 1e-5)
}

private func expectUnit(
  _ rect: StarshipUnitRect?,
  x: Double,
  y: Double,
  width: Double,
  height: Double
) {
  #expect(rect != nil)
  #expect(abs((rect?.x ?? .nan) - x) < 1e-5)
  #expect(abs((rect?.y ?? .nan) - y) < 1e-5)
  #expect(abs((rect?.width ?? .nan) - width) < 1e-5)
  #expect(abs((rect?.height ?? .nan) - height) < 1e-5)
}
