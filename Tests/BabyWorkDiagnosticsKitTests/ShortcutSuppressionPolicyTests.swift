import Testing

@testable import BabyWorkDiagnosticsKit

@Test("La politique absorbe les raccourcis système surveillés")
func policySuppressesMonitoredShortcuts() {
  let cases: [(MonitoredShortcut, UInt16, InputModifierMask)] = [
    (.commandSpace, MacVirtualKeyCode.space, [.command]),
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
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.space,
      modifiers: [.option]
    ) == .allow
  )
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.escape,
      modifiers: [.command]
    ) == .allow
  )
}

@Test("Les libellés des raccourcis surveillés restent stables")
func monitoredShortcutDisplayNamesAreStable() {
  #expect(MonitoredShortcut.commandSpace.displayName == "Commande-Espace")
  #expect(MonitoredShortcut.optionCommandEscape.displayName == "Option-Commande-Échap")
  #expect(MonitoredShortcut.allCases.count == 9)
}
