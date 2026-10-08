import Testing

@testable import CmdBabyKit

@Test("Hors session, la vérification et la mise à jour trouvée passent")
func updateSessionGateAllowsOutsideSession() {
  var gate = UpdateSessionGate()
  let allowed = gate.allows(sessionActive: false)
  let recheck = gate.sessionDidEnd()
  #expect(allowed)
  #expect(recheck == false)
}

@Test("Une mise à jour trouvée pendant une session est refusée, puis recherchée à la fin")
func updateSessionGateDefersUpdateFoundDuringSession() {
  var gate = UpdateSessionGate()
  let checkAllowed = gate.allows(sessionActive: false)
  let updateAllowed = gate.allows(sessionActive: true)
  let firstEnd = gate.sessionDidEnd()
  let secondEnd = gate.sessionDidEnd()
  #expect(checkAllowed)
  #expect(updateAllowed == false)
  #expect(firstEnd)
  #expect(secondEnd == false)
}
