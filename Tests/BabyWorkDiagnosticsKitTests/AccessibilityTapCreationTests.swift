import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Un tap créé du premier coup n’affiche pas le prompt Accessibilité")
func successfulFirstTapCreateDoesNotPrompt() {
  var createCount = 0
  var promptCount = 0

  let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
    isProcessTrusted: { false },
    promptForTrust: { promptCount += 1 },
    create: { () -> Int? in
      createCount += 1
      return 1
    }
  )

  #expect(port == 1)
  #expect(createCount == 1)
  #expect(promptCount == 0)
}

@Test("Un échec alors que le processus est déjà de confiance n’invite pas et ne relance pas")
func trustedFailureDoesNotPromptOrRetry() {
  var createCount = 0
  var promptCount = 0

  let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
    isProcessTrusted: { true },
    promptForTrust: { promptCount += 1 },
    create: { () -> Int? in
      createCount += 1
      return nil
    }
  )

  #expect(port == nil)
  #expect(createCount == 1)
  #expect(promptCount == 0)
}

@Test("Sans Accessibilité, un échec propose le prompt puis relance la création une fois")
func untrustedFailurePromptsThenRetriesOnce() {
  var createCount = 0
  var promptCount = 0

  let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
    isProcessTrusted: { false },
    promptForTrust: { promptCount += 1 },
    create: { () -> Int? in
      createCount += 1
      return createCount == 2 ? 7 : nil
    }
  )

  #expect(port == 7)
  #expect(createCount == 2)
  #expect(promptCount == 1)
}

@Test("Sans Accessibilité, le prompt et le retry n’ont lieu qu’une fois")
func untrustedFailureDoesNotLoopPromptOrRetry() {
  var createCount = 0
  var promptCount = 0

  let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
    isProcessTrusted: { false },
    promptForTrust: { promptCount += 1 },
    create: { () -> Int? in
      createCount += 1
      return nil
    }
  )

  #expect(port == nil)
  #expect(createCount == 2)
  #expect(promptCount == 1)
}
