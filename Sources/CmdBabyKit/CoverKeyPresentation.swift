import Foundation

/// Key window de la couverture principale après la présentation kiosque.
/// Un seul `makeKey` peut rater : AppKit n’a pas encore pris l’activation.
public enum CoverKeyPresentation {
  /// Tentatives `activate` + `makeKey` après un premier échec.
  public static let maxMakeKeyRetries = 5
  /// Pause entre deux tentatives tant que la couverture n’est pas key.
  public static let makeKeyRetryDelay: TimeInterval = 0.075
}

/// Séquence pour rendre la couverture principale key.
/// Un échec après retries n’annule pas la session : AppKit peut refuser le key
/// (activation pas encore prise). Le journal `covers.key … outcome=fail`
/// signifie alors qu’un clic sur la couverture peut encore être nécessaire.
public struct CoverKeySequence: Equatable, Sendable {
  public enum Phase: Equatable, Sendable {
    case makingKey
    case retryingMakeKey
    case finished(outcome: LifecycleLog.CoverKeyOutcome)
  }

  public private(set) var phase: Phase = .makingKey
  private var completedAttempts = 0

  public init() {}

  public var shouldMakeKey: Bool {
    switch phase {
    case .makingKey, .retryingMakeKey:
      true
    case .finished:
      false
    }
  }

  public var makeKeyIsRetry: Bool {
    if case .retryingMakeKey = phase { return true }
    return false
  }

  public var finishedOutcome: LifecycleLog.CoverKeyOutcome? {
    if case .finished(let outcome) = phase { return outcome }
    return nil
  }

  @discardableResult
  public mutating func recordMakeKey(isKey: Bool) -> LifecycleLogEvent {
    let retry = completedAttempts
    completedAttempts += 1
    let outcome: LifecycleLog.CoverKeyOutcome = isKey ? .success : .fail
    if outcome == .success {
      phase = .finished(outcome: .success)
    } else if retry < CoverKeyPresentation.maxMakeKeyRetries {
      phase = .retryingMakeKey
    } else {
      phase = .finished(outcome: .fail)
    }
    return .coversKey(isKey: isKey, outcome: outcome, retry: retry)
  }
}
