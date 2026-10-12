import Foundation

/// Journal de cycle de vie : lignes stables pour Console et fichier, sans donnée clavier.
///
/// Règle : jamais de caractère tapé, de keycode, de phrase de sortie ni de progression de phrase
/// dans un journal. Les chemins passent par `displayPath` : pas de nom d’utilisateur en clair.
public enum LifecycleLog {
  /// Chemin avec `~` à la place du dossier personnel.
  public static func displayPath(_ path: String) -> String {
    (path as NSString).abbreviatingWithTildeInPath
  }

  public static let subsystem = AppIdentity.logSubsystem

  public enum Category: String, Sendable {
    case lifecycle = "Lifecycle"
    case session = "Session"
    case inputFilter = "InputFilter"
    case settings = "Settings"
    case kioskTeardown = "KioskTeardown"
  }

  public enum SessionStopKind: String, Sendable {
    case adultExit
    case explicitQuit
  }

  public enum TeardownCaller: String, Sendable {
    case swift
  }

  public enum SettingsOrderFrontOutcome: String, Sendable {
    case success
    case fail
  }

  public enum CoverKeyOutcome: String, Sendable {
    case success
    case fail
  }

  public enum TerminateReply: String, Sendable {
    case now
    case cancel
  }

  public static func fileLine(
    for event: LifecycleLogEvent,
    at date: Date,
    timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
  ) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = timeZone
    formatter.formatOptions = [.withInternetDateTime]
    return "\(formatter.string(from: date)) [\(event.category.rawValue)] \(event.message)"
  }
}

public protocol LifecycleLogSink: Sendable {
  func write(_ event: LifecycleLogEvent)
}

public final class LifecycleLogRecorder: @unchecked Sendable {
  public static let shared = LifecycleLogRecorder()

  private let lock = NSLock()
  private var sinks: [any LifecycleLogSink]
  private var didInstallStandardSinks = false

  public init(sinks: [any LifecycleLogSink] = []) {
    self.sinks = sinks
  }

  public func emit(_ event: LifecycleLogEvent) {
    lock.lock()
    let current = sinks
    lock.unlock()
    for sink in current {
      sink.write(event)
    }
  }

  public func addSink(_ sink: any LifecycleLogSink) {
    lock.lock()
    sinks.append(sink)
    lock.unlock()
  }

  public func installStandardSinks() {
    lock.lock()
    if didInstallStandardSinks {
      lock.unlock()
      return
    }
    didInstallStandardSinks = true
    lock.unlock()
    addSink(OSLogLifecycleLogSink())
    let file = LifecycleLogFile()
    file.purgeOldFiles()
    addSink(file)
  }
}

public enum LifecycleLogEvent: Equatable, Sendable {
  case statusItemCreate
  case activationPolicy(before: String, after: String)
  case sessionStart(origin: SessionLaunchRequest.Origin)
  /// Lien reçu pendant une session : rien n’est affiché, l’URL n’est pas journalisée.
  case sessionLinkIgnored
  case sessionPhase(from: KioskSessionPhase, to: KioskSessionPhase)
  case sessionStop(kind: LifecycleLog.SessionStopKind)
  case teardownBegin(shouldQuit: Bool, coverCount: Int, caller: LifecycleLog.TeardownCaller)
  case teardownDone(shouldQuit: Bool, coverCount: Int, caller: LifecycleLog.TeardownCaller)
  case tapCreate
  case tapEnable
  case tapDisable(reason: String)
  case tapFail(reason: String)
  case tapReenable(reason: String)
  case settingsShowRequest
  case settingsOrderFront(
    isVisible: Bool,
    isKeyWindow: Bool,
    outcome: LifecycleLog.SettingsOrderFrontOutcome,
    retry: Int
  )
  case coversKey(
    isKey: Bool,
    outcome: LifecycleLog.CoverKeyOutcome,
    retry: Int
  )
  case terminateRequest
  case applicationShouldTerminate(reply: LifecycleLog.TerminateReply)
  case statusItemAlive(Bool)
  case statusIconMissing
  /// Bundle de ressources absent du `.app` : bug d’empaquetage.
  case resourceBundleMissing(name: String)
  case sessionActivationFail(reason: String, binaryPath: String)
  case coversFollowScreens(added: Int, removed: Int, reframed: Int)
  case displaySleepAssertion(taken: Bool)
  case guardTapLost
  case guardSecureInput
  case guardRefocus

  public var category: LifecycleLog.Category {
    switch self {
    case .statusItemCreate, .activationPolicy, .terminateRequest, .applicationShouldTerminate,
      .statusItemAlive, .statusIconMissing, .resourceBundleMissing:
      .lifecycle
    case .sessionStart(_), .sessionLinkIgnored, .sessionPhase, .sessionStop, .coversKey,
      .sessionActivationFail,
      .coversFollowScreens, .displaySleepAssertion, .guardTapLost, .guardSecureInput, .guardRefocus:
      .session
    case .tapCreate, .tapEnable, .tapDisable, .tapFail, .tapReenable:
      .inputFilter
    case .settingsShowRequest, .settingsOrderFront:
      .settings
    case .teardownBegin, .teardownDone:
      .kioskTeardown
    }
  }

  public var message: String {
    switch self {
    case .statusItemCreate:
      return "statusItem.create"
    case .activationPolicy(let before, let after):
      return "activationPolicy before=\(before) after=\(after)"
    case .sessionStart(let origin):
      return "session.start origin=\(origin.rawValue)"
    case .sessionLinkIgnored:
      return "session.link.ignored"
    case .sessionPhase(let from, let to):
      return "session.phase from=\(from.logName) to=\(to.logName)"
    case .sessionStop(let kind):
      return "session.stop kind=\(kind.rawValue)"
    case .teardownBegin(let shouldQuit, let coverCount, let caller):
      return "teardown.begin should_quit=\(shouldQuit) cover_count=\(coverCount) caller=\(caller.rawValue)"
    case .teardownDone(let shouldQuit, let coverCount, let caller):
      return "teardown.done should_quit=\(shouldQuit) cover_count=\(coverCount) caller=\(caller.rawValue)"
    case .tapCreate:
      return "tap.create"
    case .tapEnable:
      return "tap.enable"
    case .tapDisable(let reason):
      return "tap.disable reason=\(reason)"
    case .tapFail(let reason):
      return "tap.fail reason=\(reason)"
    case .tapReenable(let reason):
      return "tap.reenable reason=\(reason)"
    case .settingsShowRequest:
      return "settings.show.request"
    case .settingsOrderFront(let isVisible, let isKeyWindow, let outcome, let retry):
      let base =
        "settings.orderFront isVisible=\(isVisible) isKeyWindow=\(isKeyWindow) outcome=\(outcome.rawValue)"
      return retry > 0 ? "\(base) retry=\(retry)" : base
    case .coversKey(let isKey, let outcome, let retry):
      let base = "covers.key isKey=\(isKey) outcome=\(outcome.rawValue)"
      return retry > 0 ? "\(base) retry=\(retry)" : base
    case .coversFollowScreens(let added, let removed, let reframed):
      return "covers.followScreens added=\(added) removed=\(removed) reframed=\(reframed)"
    case .displaySleepAssertion(let taken):
      return "power.displaySleep prevented=\(taken)"
    case .guardTapLost:
      return "guard.tapLost"
    case .guardSecureInput:
      return "guard.secureInput"
    case .guardRefocus:
      return "guard.refocus"
    case .resourceBundleMissing(let name):
      return "resources.missing bundle=\(name)"
    case .statusIconMissing:
      return "statusItem.icon missing fallback=\(MenuBarAgent.fallbackSymbolName)"
    case .terminateRequest:
      return "terminate.request"
    case .applicationShouldTerminate(let reply):
      return "applicationShouldTerminate reply=\(reply.rawValue)"
    case .statusItemAlive(let alive):
      return "statusItem.alive=\(alive)"
    case .sessionActivationFail(let reason, let binaryPath):
      return "session.activation.fail reason=\(reason) binary=\(binaryPath)"
    }
  }
}

extension KioskSessionPhase {
  fileprivate var logName: String {
    switch self {
    case .configuration:
      "configuration"
    case .preparing:
      "preparing"
    case .activating:
      "activating"
    case .active:
      "active"
    case .stopping:
      "stopping"
    case .failed:
      "failed"
    }
  }
}
