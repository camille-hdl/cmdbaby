import Foundation

/// Garantit qu’une sortie adulte atteint l’idle : action immédiate, puis filet
/// si `perform` n’aboutit pas (Task MainActor perdu, timeout).
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
      perform: {
        MainQueueHop.run(perform)
      },
      isIdle: isIdle,
      forceIdle: {
        MainQueueHop.run(forceIdle)
      },
      scheduleFallback: { work in
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
      }
    )
  }
}

public enum MainQueueHop {
  public static func run(_ work: @escaping @Sendable () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }
}
