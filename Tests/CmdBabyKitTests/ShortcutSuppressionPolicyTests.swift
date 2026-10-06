import Testing

@testable import CmdBabyKit

@Test("La politique absorbe les raccourcis système surveillés")
func policySuppressesMonitoredShortcuts() {
  let cases: [(MonitoredShortcut, UInt16, InputModifierMask)] = [
    (.commandSpace, MacVirtualKeyCode.space, [.command]),
    (.optionSpace, MacVirtualKeyCode.space, [.option]),
    (.controlSpace, MacVirtualKeyCode.space, [.control]),
    (.controlOptionSpace, MacVirtualKeyCode.space, [.control, .option]),
    (.commandTab, MacVirtualKeyCode.tab, [.command]),
    (.commandQ, MacVirtualKeyCode.ansiQ, [.command]),
    (.commandH, MacVirtualKeyCode.ansiH, [.command]),
    (.commandM, MacVirtualKeyCode.ansiM, [.command]),
    (.optionCommandEscape, MacVirtualKeyCode.escape, [.option, .command]),
    (.controlUp, MacVirtualKeyCode.upArrow, [.control]),
    (.controlDown, MacVirtualKeyCode.downArrow, [.control]),
    (.controlCommandQ, MacVirtualKeyCode.ansiQ, [.control, .command]),
  ]

  for item in cases {
    let decision = ShortcutSuppressionPolicy.decision(
      keyCode: item.1,
      modifiers: item.2
    )
    #expect(decision == .suppress(item.0), "Échec pour \(item.0.displayName)")
  }
}

@Test("Commande-Tab reste absorbé avec Majuscule")
func policyIgnoresShiftForCommandTab() {
  let decision = ShortcutSuppressionPolicy.decision(
    keyCode: MacVirtualKeyCode.tab,
    modifiers: [.command, .shift]
  )
  #expect(decision == .suppress(.commandTab))
}

@Test("Contrôle-Commande-Q n’est pas confondu avec Commande-Q")
func policyDistinguishesControlCommandQ() {
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.command]
    ) == .suppress(.commandQ)
  )
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.control, .command]
    ) == .suppress(.controlCommandQ)
  )
}

@Test("Les frappes ordinaires restent autorisées")
func policyAllowsOrdinaryKeyPresses() {
  #expect(
    ShortcutSuppressionPolicy.decision(keyCode: MacVirtualKeyCode.ansiQ, modifiers: []) == .allow
  )
  #expect(
    ShortcutSuppressionPolicy.decision(keyCode: MacVirtualKeyCode.space, modifiers: []) == .allow
  )
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.space,
      modifiers: [.shift]
    ) == .allow
  )
  #expect(
    ShortcutSuppressionPolicy.decision(keyCode: MacVirtualKeyCode.escape, modifiers: [.shift]) == .allow
  )
  #expect(
    ShortcutSuppressionPolicy.decision(keyCode: MacVirtualKeyCode.ansiQ, modifiers: [.option]) == .allow
  )
}

@Test("Commande-Q et Commande-M suivent la lettre, pas la position QWERTY")
func policyMatchesLettersIndependentOfAnsiPosition() {
  let azertyQ = ShortcutSuppressionPolicy.decision(
    keyCode: 0x00,
    modifiers: [.command],
    letter: "q"
  )
  let azertyM = ShortcutSuppressionPolicy.decision(
    keyCode: 0x29,
    modifiers: [.command],
    letter: "m"
  )
  let azertyControlCommandQ = ShortcutSuppressionPolicy.decision(
    keyCode: 0x00,
    modifiers: [.control, .command],
    letter: "q"
  )
  #expect(azertyQ == .suppress(.commandQ))
  #expect(azertyM == .suppress(.commandM))
  #expect(azertyControlCommandQ == .suppress(.controlCommandQ))
}

@Test("Les libellés des raccourcis surveillés restent stables")
func monitoredShortcutDisplayNamesAreStable() {
  #expect(MonitoredShortcut.commandSpace.displayName == "Commande-Espace")
  #expect(MonitoredShortcut.controlSpace.displayName == "Contrôle-Espace")
  #expect(MonitoredShortcut.controlOptionSpace.displayName == "Contrôle-Option-Espace")
  #expect(MonitoredShortcut.optionCommandEscape.displayName == "Option-Commande-Échap")
  #expect(MonitoredShortcut.allCases.count == 16)
}

@Test("En session, les raccourcis système qui passaient encore sont absorbés")
func policySuppressesRemainingSystemShortcuts() {
  let leftArrow: UInt16 = 0x7B
  let rightArrow: UInt16 = 0x7C
  let digits: [UInt16] = [0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19]
  let digit3: UInt16 = 0x14
  let digit4: UInt16 = 0x15
  let digit5: UInt16 = 0x17
  let digit8: UInt16 = 0x1C
  let f5: UInt16 = 0x60

  var shortcuts: [(UInt16, InputModifierMask)] = [
    (leftArrow, [.control]),
    (rightArrow, [.control]),
    (MacVirtualKeyCode.space, [.control, .command]),
    (MacVirtualKeyCode.space, [.command, .option]),
    (digit3, [.command, .shift]),
    (digit4, [.command, .shift]),
    (digit5, [.command, .shift]),
    (f5, [.command]),
    (f5, [.command, .option]),
    (digit8, [.command, .option]),
    (digit8, [.control, .option, .command]),
  ]
  shortcuts += digits.map { ($0, [.control]) }

  for (keyCode, modifiers) in shortcuts {
    let decision = ShortcutSuppressionPolicy.decision(keyCode: keyCode, modifiers: modifiers)
    #expect(decision != .allow, "Laissé passer : keyCode \(keyCode), modificateurs \(modifiers.rawValue)")
  }
  #expect(
    ShortcutSuppressionPolicy.decision(keyCode: leftArrow, modifiers: [.control])
      == .suppress(.otherCommandOrControl)
  )
}

@Test("F11 et les autres touches de fonction sont absorbées, avec ou sans modificateur")
func policySuppressesFunctionKeys() {
  let f11: UInt16 = 0x67
  #expect(ShortcutSuppressionPolicy.decision(keyCode: f11, modifiers: []) == .suppress(.functionKey))
  #expect(ShortcutSuppressionPolicy.decision(keyCode: 0x7A, modifiers: []) == .suppress(.functionKey))
  #expect(ShortcutSuppressionPolicy.decision(keyCode: f11, modifiers: [.shift]) == .suppress(.functionKey))
}

@Test("La touche fn/Globe est absorbée ; les autres modificateurs passent")
func policySuppressesGlobeKey() {
  #expect(ShortcutSuppressionPolicy.flagsChangedDecision(keyCode: 0x3F) == .suppress(.fnGlobe))
  #expect(ShortcutSuppressionPolicy.flagsChangedDecision(keyCode: 0x38) == .allow)
}

@Test("Les touches auxiliaires (type 14, sous-type 8) sont absorbées ; les autres sous-types passent")
func policySuppressesAuxiliaryKeys() {
  #expect(ShortcutSuppressionPolicy.systemDefinedDecision(subtype: 8) == .suppress(.auxiliaryKey))
  #expect(ShortcutSuppressionPolicy.systemDefinedDecision(subtype: 7) == .allow)
}

@Test("Les sorties adulte restent possibles : Maj-Échap, lettres, Entrée")
func policyKeepsAdultExitsUsable() {
  #expect(ShortcutSuppressionPolicy.decision(keyCode: MacVirtualKeyCode.escape, modifiers: [.shift]) == .allow)
  #expect(ShortcutSuppressionPolicy.decision(keyCode: 0x23, modifiers: [], letter: "p") == .allow)
  #expect(ShortcutSuppressionPolicy.decision(keyCode: 0x23, modifiers: [.shift], letter: "p") == .allow)
  #expect(ShortcutSuppressionPolicy.decision(keyCode: 0x24, modifiers: []) == .allow)
}
