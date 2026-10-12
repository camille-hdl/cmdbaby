import Foundation
import Testing

@testable import CmdBabyKit

@Test("cmdbaby://session/start lance une session avec les réglages enregistrés")
func sessionStartLinkWithoutParametersUsesSavedSettings() throws {
  let request = try #require(parsed("cmdbaby://session/start"))

  #expect(request == SessionLaunchRequest(origin: .link))
}

@Test("Le lien porte le mode et la durée de cette session")
func sessionStartLinkCarriesModeAndDuration() throws {
  let request = try #require(parsed("cmdbaby://session/start?mode=starship&minutes=10"))

  #expect(request == SessionLaunchRequest(origin: .link, mode: .starship, durationMinutes: 10))
}

@Test("Le mode seul, ou la durée seule, reste optionnel")
func sessionStartLinkAcceptsEitherParameterAlone() throws {
  let modeOnly = try #require(parsed("cmdbaby://session/start?mode=ocean"))
  let minutesOnly = try #require(parsed("cmdbaby://session/start?minutes=2"))

  #expect(modeOnly.mode == .ocean)
  #expect(modeOnly.durationMinutes == nil)
  #expect(minutesOnly.mode == nil)
  #expect(minutesOnly.durationMinutes == 2)

  let padded = try #require(parsed("cmdbaby://session/start?minutes=01"))
  #expect(padded.durationMinutes == 1)
}

@Test("Une durée entière hors borne est lue ; le refus n’est pas une erreur de format")
func sessionStartLinkReadsAnOutOfRangeDuration() throws {
  let zero = try #require(parsed("cmdbaby://session/start?minutes=0"))
  let high = try #require(parsed("cmdbaby://session/start?minutes=121"))

  #expect(zero.durationMinutes == 0)
  #expect(high.durationMinutes == 121)
}

@Test("Un schéma, un chemin, un mode ou une durée illisible est refusé", arguments: [
  ("https://session/start", SessionLinkFailure.unknownScheme),
  ("cmdbaby://session/stop", SessionLinkFailure.unknownPath),
  ("cmdbaby://other/start", SessionLinkFailure.unknownPath),
  ("cmdbaby://session/start?mode=galaxy", SessionLinkFailure.unknownMode),
  ("cmdbaby://session/start?minutes=dix", SessionLinkFailure.durationNotInteger),
  ("cmdbaby://session/start?minutes=1.5", SessionLinkFailure.durationNotInteger),
  ("cmdbaby://session/start?mode=starship&mode=ocean", SessionLinkFailure.duplicateParameter),
  ("cmdbaby://session/start?minutes=10&minutes=2", SessionLinkFailure.duplicateParameter),
  ("cmdbaby://session/start?minute=10", SessionLinkFailure.unknownParameter),
  ("cmdbaby://session/start?mode=starship&minute=10", SessionLinkFailure.unknownParameter),
  ("cmdbaby://session/start?mode", SessionLinkFailure.unknownMode),
  ("cmdbaby://session/start?minutes", SessionLinkFailure.durationNotInteger),
])
func sessionStartLinkRejectsEachMalformedCase(_ raw: String, _ failure: SessionLinkFailure) {
  #expect(SessionLinkParser.parse(URL(string: raw)!) == .failure(failure))
}

private func parsed(_ raw: String) -> SessionLaunchRequest? {
  guard case .success(let request) = SessionLinkParser.parse(URL(string: raw)!) else {
    return nil
  }
  return request
}
