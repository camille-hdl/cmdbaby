import Foundation

/// Garantit qu’une sortie adulte atteint l’idle : action immédiate, puis filet
/// si `perform` n’aboutit pas (hop MainActor perdu, timeout).
public struct AdultExitPipeline: Sendable {
  public static let fallbackDelay: TimeInterval = 0.4

  public init() {}

  public func complete(
    perform: @escaping @Sendable () -> Void,
    isIdle: @escaping @Sendable () -> Bool,
    forceIdle: @escaping @Sendable () -> Void,
    scheduleFallback: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void
  ) {
    perform()
    if isIdle() {
      return
    }
    scheduleFallback {
      guard !isIdle() else { return }
      forceIdle()
    }
  }

  public func completeOnMain(
    perform: @escaping @Sendable () -> Void,
    isIdle: @escaping @Sendable () -> Bool,
    forceIdle: @escaping @Sendable () -> Void,
    delay: TimeInterval = Self.fallbackDelay
  ) {
    complete(
      perform: perform,
      isIdle: isIdle,
      forceIdle: forceIdle,
      scheduleFallback: { work in
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
      }
    )
  }
}

/// Enfile sur `DispatchQueue.main` (exécuteur MainActor), jamais en ligne
/// depuis `Thread.isMainThread` / CFRunLoop.
public enum MainActorHop {
  public static func run(_ work: @escaping @MainActor @Sendable () -> Void) {
    DispatchQueue.main.async {
      MainActor.assumeIsolated(work)
    }
  }
}
