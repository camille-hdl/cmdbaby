import Testing

@testable import BabyWorkDiagnosticsKit

@Test("La barre d’espace demande la toupie")
func starshipKeySpaceAsksForASpin() {
  #expect(StarshipKey.action(keyCode: 49, isARepeat: false) == .spin)
}

@Test("Une barre d’espace maintenue est ignorée")
func starshipKeyRepeatedSpaceIsIgnored() {
  #expect(StarshipKey.action(keyCode: 49, isARepeat: true) == .ignored)
}

@Test("La touche A n’est pas la toupie")
func starshipKeyLetterAIsOther() {
  #expect(StarshipKey.action(keyCode: 0, isARepeat: false) == .other)
}

@Test("La touche Entrée n’est pas la toupie")
func starshipKeyReturnIsOther() {
  #expect(StarshipKey.action(keyCode: 36, isARepeat: false) == .other)
}

@Test("Une répétition de la touche A est ignorée")
func starshipKeyRepeatedLetterAIsIgnored() {
  #expect(StarshipKey.action(keyCode: 0, isARepeat: true) == .ignored)
}
