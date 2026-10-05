import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Un seul écran est choisi")
func largestScreenIndexSelectsTheOnlyScreen() {
  let screens = [
    TerminalScreen(index: 2, x: 0, y: 0, width: 1440, height: 900)
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 2)
}

@Test("Le plus grand écran l’emporte")
func largestScreenIndexPrefersGreaterArea() {
  let screens = [
    TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900),
    TerminalScreen(index: 1, x: 1440, y: 0, width: 2560, height: 1440),
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 1)
}

@Test("À surface égale, le plus petit index l’emporte")
func largestScreenIndexTieBreaksToSmallerIndex() {
  let screens = [
    TerminalScreen(index: 3, x: 0, y: 0, width: 200, height: 100),
    TerminalScreen(index: 1, x: 200, y: 0, width: 100, height: 200),
  ]
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == 1)
}

@Test("Une liste vide ne désigne aucun écran")
func largestScreenIndexOfEmptyListIsNil() {
  let screens: [TerminalScreen] = []
  #expect(TerminalScreenLayout.largestScreenIndex(screens) == nil)
}
