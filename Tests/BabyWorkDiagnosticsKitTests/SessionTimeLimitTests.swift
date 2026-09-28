import Testing

@testable import BabyWorkDiagnosticsKit

@Test("La session dure 20 minutes par défaut")
func sessionTimeLimitDefaultsToTwentyMinutes() {
  let limit = SessionTimeLimit(startedAt: 0)
  #expect(limit.duration == 20 * 60)
  #expect(limit.progress(at: 0) == 0)
  #expect(!limit.isComplete(at: 0))
}

@Test("À mi-parcours le contour est à moitié dessiné")
func sessionTimeLimitIsHalfDrawnAtTheMidpoint() {
  let limit = SessionTimeLimit(startedAt: 1_000)
  #expect(limit.progress(at: 1_600) == 0.5)
  #expect(!limit.isComplete(at: 1_600))
}

@Test("À 20 minutes le contour est complet et la session se termine")
func sessionTimeLimitCompletesWhenTheDurationElapses() {
  let limit = SessionTimeLimit(startedAt: 1_000)
  let deadline = Double(1_000 + 20 * 60)
  #expect(limit.progress(at: deadline) == 1)
  #expect(limit.isComplete(at: deadline))
  #expect(limit.progress(at: deadline + 30) == 1)
  #expect(limit.isComplete(at: deadline + 30))
}

@Test("Avant le départ le contour reste vide")
func sessionTimeLimitStaysEmptyBeforeTheStart() {
  let limit = SessionTimeLimit(startedAt: 50, duration: 10)
  #expect(limit.progress(at: 49) == 0)
  #expect(!limit.isComplete(at: 49))
}

@Test("Une durée fournie remplace les 20 minutes")
func customDurationReplacesTheDefault() {
  let limit = SessionTimeLimit(startedAt: 0, duration: 10)
  #expect(limit.progress(at: 5) == 0.5)
  #expect(!limit.isComplete(at: 9))
  #expect(limit.isComplete(at: 10))
}

@Test("Une durée nulle termine tout de suite, pour ne pas bloquer la session")
func nonPositiveDurationCompletesImmediately() {
  let limit = SessionTimeLimit(startedAt: 0, duration: 0)
  #expect(limit.progress(at: 0) == 1)
  #expect(limit.isComplete(at: 0))
}
