import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Premier makeKey pas key : un retry")
func failedFirstCoverMakeKeySchedulesRetry() {
  var sequence = CoverKeySequence()
  let event = sequence.recordMakeKey(isKey: false)
  #expect(
    event
      == .coversKey(
        isKey: false,
        outcome: .fail,
        retry: 0
      )
  )
  #expect(sequence.shouldMakeKey)
  #expect(sequence.makeKeyIsRetry)
}

@Test("MakeKey key : succès journalisé, terminé")
func successfulCoverMakeKeyFinishesWithSuccess() {
  var sequence = CoverKeySequence()
  let event = sequence.recordMakeKey(isKey: true)
  #expect(
    event
      == .coversKey(
        isKey: true,
        outcome: .success,
        retry: 0
      )
  )
  #expect(!sequence.shouldMakeKey)
  #expect(sequence.finishedOutcome == .success)
}

@Test("Après 5 retries toujours pas key : échec journalisé, terminé")
func exhaustedCoverMakeKeyRetriesFinishWithFail() {
  var sequence = CoverKeySequence()
  for _ in 1...5 {
    _ = sequence.recordMakeKey(isKey: false)
    #expect(sequence.shouldMakeKey)
  }
  let event = sequence.recordMakeKey(isKey: false)
  #expect(
    event
      == .coversKey(
        isKey: false,
        outcome: .fail,
        retry: 5
      )
  )
  #expect(!sequence.shouldMakeKey)
  #expect(sequence.finishedOutcome == .fail)
}

@Test("Retry devenu key : succès journalisé retry=N")
func successfulCoverMakeKeyRetryFinishesWithSuccess() {
  var sequence = CoverKeySequence()
  _ = sequence.recordMakeKey(isKey: false)
  _ = sequence.recordMakeKey(isKey: false)
  let event = sequence.recordMakeKey(isKey: true)
  #expect(
    event
      == .coversKey(
        isKey: true,
        outcome: .success,
        retry: 2
      )
  )
  #expect(sequence.finishedOutcome == .success)
}

@Test("Le délai de retry reste dans 50–100 ms")
func coverMakeKeyRetryDelayIsBounded() {
  #expect(CoverKeyPresentation.makeKeyRetryDelay >= 0.05)
  #expect(CoverKeyPresentation.makeKeyRetryDelay <= 0.1)
}
