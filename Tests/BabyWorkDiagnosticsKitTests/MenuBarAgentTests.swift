import Testing

@testable import BabyWorkDiagnosticsKit

@Test("L’agent idle n’a pas d’icône Dock")
func menuBarAgentUsesAccessoryActivationPolicy() {
  #expect(MenuBarAgent.activationPolicy == .accessory)
}

@Test("Le status item est un SF Symbol template, pas un emoji")
func menuBarAgentStatusItemIsTemplateSymbol() {
  #expect(MenuBarAgent.systemSymbolName == "fish")
  #expect(MenuBarAgent.usesTemplateImage)
  #expect(MenuBarAgent.systemSymbolName.unicodeScalars.allSatisfy { $0.isASCII })
}

@Test("Le menu fixe a Lancer session, Réglages… et Quitter")
func menuBarAgentMenuHasThreeFixedEntries() {
  #expect(MenuBarAgent.items.map(\.title) == ["Lancer session", "Réglages…", "Quitter"])
}

@Test("Seul Quitter termine le process ; les autres actions sont des stubs")
func menuBarAgentOnlyQuitTerminatesProcess() {
  #expect(MenuBarAgent.items.map(\.action) == [.stub, .stub, .terminate])
}
