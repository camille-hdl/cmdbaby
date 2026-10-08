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

@Test("La dérive 0 et 1 d’un écran 1440 × 900 restent dans l’image, écartées de la marge")
func skyboxFramingKeepsASingleScreenDriftInsideTheImage() {
  let screens = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 0, verticalMargin: 0.08
    ),
    x: 0.132, y: 0.08, width: 0.736, height: 0.92
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 1, verticalMargin: 0.08
    ),
    x: 0.132, y: 0, width: 0.736, height: 0.92
  )
}

@Test("Sans dérive, deux écrans côte à côte gardent l’aspect-fill ; la dérive 1 descend de la marge")
func skyboxFramingAtDriftZeroStaysTheSideBySideAspectFill() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1440, height: 900),
  ]
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 0, verticalMargin: 0.08
    ),
    x: 0, y: 0.1875, width: 0.5, height: 0.625
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 1, among: screens, drift: 0, verticalMargin: 0.08
    ),
    x: 0.5, y: 0.1875, width: 0.5, height: 0.625
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 1, verticalMargin: 0.08
    ),
    x: 0, y: 0.1075, width: 0.5, height: 0.625
  )
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 1, among: screens, drift: 1, verticalMargin: 0.08
    ),
    x: 0.5, y: 0.1075, width: 0.5, height: 0.625
  )
}

@Test("Deux écrans voisins restent jointifs à toute dérive")
func skyboxFramingKeepsNeighborsJoinedAtAnyDrift() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 1440, height: 900),
  ]
  for drift in [0.0, 0.25, 0.5, 1.0] {
    let left = StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: drift, verticalMargin: 0.08
    )
    let right = StarshipSkyboxFraming.contentsRect(
      forScreen: 1, among: screens, drift: drift, verticalMargin: 0.08
    )
    #expect(left != nil)
    #expect(right != nil)
    #expect(abs((left?.x ?? 0) + (left?.width ?? 0) - (right?.x ?? 1)) < 1e-5)
    #expect(abs((left?.y ?? 0) - (right?.y ?? 1)) < 1e-5)
    #expect(abs((left?.height ?? 0) - (right?.height ?? 1)) < 1e-5)
    #expect((left?.x ?? -1) >= 0)
    #expect((left?.y ?? -1) >= 0)
    #expect((left?.x ?? 0) + (left?.width ?? 2) <= 1 + 1e-9)
    #expect((left?.y ?? 0) + (left?.height ?? 2) <= 1 + 1e-9)
    #expect((right?.x ?? 0) + (right?.width ?? 2) <= 1 + 1e-9)
    #expect((right?.y ?? 0) + (right?.height ?? 2) <= 1 + 1e-9)
  }
  expectUnit(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 0.25, verticalMargin: 0.08
    ),
    x: 0, y: 0.1675, width: 0.5, height: 0.625
  )
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
