import Testing

@testable import CmdBabyKit

@Test("Un processus de confiance n’affiche pas le prompt Accessibilité")
func trustedProcessDoesNotPrompt() {
  var createCount = 0
  var promptCount = 0

  let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
    isProcessTrusted: { true },
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

@Test("Sans Accessibilité, le prompt précède la création du tap")
func untrustedProcessPromptsBeforeCreate() {
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
  #expect(promptCount == 1)
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

@Test("Sans Accessibilité, un échec relance la création une fois après le prompt")
func untrustedFailureRetriesOnceAfterPrompt() {
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
