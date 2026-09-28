import AppKit
import BabyWorkAppKitBridge
import BabyWorkDiagnosticsKit
import CoreFoundation
import ObjectiveC
import OSLog

/// Appels AppKit sans passer par l’isolation MainActor Swift.
final class DiagnosticRevealPump: NSObject, @unchecked Sendable {
  private let lock = NSLock()
  private weak var window: NSWindow?
  private var rebuild: (@Sendable () -> Void)?

  func attach(window: NSWindow, rebuild: @escaping @Sendable () -> Void) {
    lock.lock()
    self.window = window
    self.rebuild = rebuild
    lock.unlock()
  }

  @objc func reveal() {
    lock.lock()
    let window = window
    let rebuild = rebuild
    lock.unlock()
    guard let window else { return }
    UnsafeAppKit.orderFrontDiagnosticWindow(window)
    rebuild?()
  }

  func request() {
    DispatchQueue.main.async { [weak self] in
      self?.reveal()
    }
    CFRunLoopWakeUp(CFRunLoopGetMain())
  }
}

enum UnsafeAppKit {
  static func setPresentationOptions(_ raw: UInt) {
    typealias Setter = @convention(c) (AnyObject, Selector, UInt) -> Void
    let selector = NSSelectorFromString("setPresentationOptions:")
    guard
      let app = nsApplication(),
      let method = class_getInstanceMethod(NSApplication.self, selector)
    else {
      return
    }
    unsafeBitCast(method_getImplementation(method), to: Setter.self)(app, selector, raw)
  }

  static func hideCoverWindows(stored: [NSWindow]) -> Int {
    var seen = Set<ObjectIdentifier>()
    var hidden = 0
    for window in stored {
      hideWindow(window)
      seen.insert(ObjectIdentifier(window))
      hidden += 1
    }
    for window in allApplicationWindows() {
      guard !seen.contains(ObjectIdentifier(window)) else { continue }
      guard isCoverWindow(window) else { continue }
      hideWindow(window)
      hidden += 1
    }
    return hidden
  }

  static func orderFrontDiagnosticWindow(_ window: NSWindow) {
    setWindowLevel(window, 0)
    setAlpha(window, 1)
    setIgnoresMouseEvents(window, false)
    makeKeyAndOrderFront(window)
    activateApp()
  }

  static func makeKeyAndOrderFront(_ window: NSWindow) {
    invoke(window, NSSelectorFromString("makeKeyAndOrderFront:"), object: nil)
  }

  static func setContentView(_ window: NSWindow, _ view: NSView) {
    invoke(window, NSSelectorFromString("setContentView:"), object: view)
  }

  private static func hideWindow(_ window: NSWindow) {
    invoke(window, NSSelectorFromString("setContentView:"), object: nil)
    setIgnoresMouseEvents(window, true)
    setAlpha(window, 0)
    setWindowLevel(window, 0)
    invoke(window, NSSelectorFromString("orderOut:"), object: nil)
    invokeVoid(window, NSSelectorFromString("close"))
  }

  private static func isCoverWindow(_ window: NSWindow) -> Bool {
    let identifier = windowIdentifier(window)
    if identifier.hasPrefix("fr.camille.babywork.cover.") {
      return true
    }
    if identifier == "fr.camille.babywork.parent" {
      return false
    }
    return windowLevel(window) >= 1000
  }

  private static func setWindowLevel(_ window: NSWindow, _ level: Int) {
    typealias Setter = @convention(c) (AnyObject, Selector, Int) -> Void
    let selector = NSSelectorFromString("setLevel:")
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector) else { return }
    unsafeBitCast(method_getImplementation(method), to: Setter.self)(window, selector, level)
  }

  private static func setAlpha(_ window: NSWindow, _ alpha: Double) {
    typealias Setter = @convention(c) (AnyObject, Selector, Double) -> Void
    let selector = NSSelectorFromString("setAlphaValue:")
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector) else { return }
    unsafeBitCast(method_getImplementation(method), to: Setter.self)(window, selector, alpha)
  }

  private static func setIgnoresMouseEvents(_ window: NSWindow, _ ignores: Bool) {
    typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool) -> Void
    let selector = NSSelectorFromString("setIgnoresMouseEvents:")
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector) else { return }
    unsafeBitCast(method_getImplementation(method), to: Setter.self)(window, selector, ObjCBool(ignores))
  }

  private static func windowLevel(_ window: NSWindow) -> Int {
    typealias Getter = @convention(c) (AnyObject, Selector) -> Int
    let selector = NSSelectorFromString("level")
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector) else { return 0 }
    return unsafeBitCast(method_getImplementation(method), to: Getter.self)(window, selector)
  }

  private static func invoke(_ target: AnyObject, _ selector: Selector, object: AnyObject?) {
    typealias Fn = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector)
      ?? instanceMethod(object_getClass(target), selector)
    else {
      return
    }
    unsafeBitCast(method_getImplementation(method), to: Fn.self)(target, selector, object)
  }

  private static func invokeVoid(_ target: AnyObject, _ selector: Selector) {
    typealias Fn = @convention(c) (AnyObject, Selector) -> Void
    guard let method = instanceMethod(NSClassFromString("NSWindow"), selector)
      ?? instanceMethod(object_getClass(target), selector)
    else {
      return
    }
    unsafeBitCast(method_getImplementation(method), to: Fn.self)(target, selector)
  }

  private static func instanceMethod(_ cls: AnyClass?, _ selector: Selector) -> Method? {
    guard let cls else { return nil }
    return class_getInstanceMethod(cls, selector)
  }

  private static func nsApplication() -> AnyObject? {
    guard let appClass: AnyObject = NSClassFromString("NSApplication") else { return nil }
    return appClass.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue()
  }

  private static func activateApp() {
    guard let app = nsApplication() else { return }
    let ignoring = NSSelectorFromString("activateIgnoringOtherApps:")
    if let method = class_getInstanceMethod(NSApplication.self, ignoring) {
      typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool) -> Void
      unsafeBitCast(method_getImplementation(method), to: Setter.self)(app, ignoring, true)
      return
    }
    let activate = NSSelectorFromString("activate")
    guard let method = class_getInstanceMethod(NSApplication.self, activate) else { return }
    typealias Fn = @convention(c) (AnyObject, Selector) -> Void
    unsafeBitCast(method_getImplementation(method), to: Fn.self)(app, activate)
  }

  private static func allApplicationWindows() -> [NSWindow] {
    guard
      let app = nsApplication(),
      let raw = app.perform(NSSelectorFromString("windows"))?.takeUnretainedValue() as? [NSWindow]
    else {
      return []
    }
    return raw
  }

  private static func windowIdentifier(_ window: NSWindow) -> String {
    guard let value = window.perform(NSSelectorFromString("identifier"))?.takeUnretainedValue() else {
      return ""
    }
    if let string = value as? String {
      return string
    }
    if let string = value as? NSString {
      return string as String
    }
    if let identifier = value.perform(NSSelectorFromString("rawValue"))?.takeUnretainedValue() as? String {
      return identifier
    }
    return ""
  }
}

/// Fenêtres de couverture accessibles depuis le tap / mouseDown.
final class CoverWindowStore: @unchecked Sendable {
  private let lock = NSLock()
  private var windows: [NSWindow] = []
  private var capturedPresentation: UInt = 0

  func replaceWindows(_ windows: [NSWindow]) {
    lock.lock()
    self.windows = windows
    lock.unlock()
  }

  func setCapturedPresentation(_ raw: UInt) {
    lock.lock()
    capturedPresentation = raw
    lock.unlock()
  }

  func snapshot() -> [NSWindow] {
    lock.lock()
    defer { lock.unlock() }
    return windows
  }

  func capturedRaw() -> UInt {
    lock.lock()
    defer { lock.unlock() }
    return capturedPresentation
  }

  func hideAll() -> Int {
    lock.lock()
    let list = windows
    lock.unlock()
    return UnsafeAppKit.hideCoverWindows(stored: list)
  }

  func drop() {
    lock.lock()
    windows = []
    lock.unlock()
  }

  func closeAll() -> Int {
    let hidden = hideAll()
    drop()
    return hidden
  }
}

final class FilterHolder: @unchecked Sendable {
  private let lock = NSLock()
  private var filter: SessionInputFilter?

  func set(_ filter: SessionInputFilter?) {
    lock.lock()
    self.filter = filter
    lock.unlock()
  }

  func current() -> SessionInputFilter? {
    lock.lock()
    defer { lock.unlock() }
    return filter
  }

  func tapHandles() -> (port: CFMachPort?, loop: CFRunLoop?) {
    current()?.handles() ?? (nil, nil)
  }

  func stop() {
    lock.lock()
    let current = filter
    filter = nil
    lock.unlock()
    current?.stop()
  }
}

final class TerminationGate: @unchecked Sendable {
  private let lock = NSLock()
  private var blocked = false

  func setBlocked(_ blocked: Bool) {
    lock.lock()
    self.blocked = blocked
    lock.unlock()
  }

  func isBlocked() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return blocked
  }
}

/// Démonte le kiosque. Une sortie adulte laisse le process vivant ;
/// Quitter enchaîne `terminate:` après le même démontage (`should_quit`).
final class KioskEmergencyExit: @unchecked Sendable {
  let store: CoverWindowStore
  var hud: KioskHUD?
  var tapHandles: (@Sendable () -> (port: CFMachPort?, loop: CFRunLoop?))?
  var reveal: (@Sendable () -> Void)?
  var unblock: (@Sendable () -> Void)?
  var syncModel: (@Sendable (AdultExitKind) -> Void)?

  private let lock = NSLock()
  private var didRun = false
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "fr.camille.babywork",
    category: "KioskExit"
  )

  init(store: CoverWindowStore) {
    self.store = store
  }

  func arm() {
    lock.lock()
    didRun = false
    lock.unlock()
    SessionInputKillSwitch.shared.reset()
  }

  func run(_ kind: AdultExitKind) {
    schedule(.adultExit(kind))
  }

  func quit() {
    schedule(.explicitQuit)
  }

  private func schedule(_ request: KioskEndRequest) {
    lock.lock()
    if didRun && !request.terminatesProcess {
      lock.unlock()
      return
    }
    didRun = true
    lock.unlock()

    // Aucun appel AppKit Swift ici : ça deadlock / no-op hors de l’exécuteur MainActor.
    SessionInputKillSwitch.shared.engage()
    hud?.noteTeardown(hiddenWindows: -1)

    let windows = store.snapshot() as NSArray
    let raw = UInt64(store.capturedRaw())
    let (port, loop) = tapHandles?() ?? (nil, nil)
    let box = TeardownDoneBox(
      request: request,
      unblock: unblock,
      syncModel: syncModel
    )
    if request.terminatesProcess {
      logger.info("Quitter : démontage ObjC puis terminate")
    } else {
      logger.info("Sortie adulte : démontage ObjC planifié")
    }
    BabyWorkScheduleKioskTeardown(
      Unmanaged.passRetained(windows).toOpaque(),
      raw,
      port.map { Unmanaged.passUnretained($0).toOpaque() },
      loop.map { Unmanaged.passUnretained($0).toOpaque() },
      request.terminatesProcess,
      teardownDoneTrampoline,
      Unmanaged.passRetained(box).toOpaque()
    )
  }
}

private final class TeardownDoneBox: @unchecked Sendable {
  let request: KioskEndRequest
  let unblock: (@Sendable () -> Void)?
  let syncModel: (@Sendable (AdultExitKind) -> Void)?

  init(
    request: KioskEndRequest,
    unblock: (@Sendable () -> Void)?,
    syncModel: (@Sendable (AdultExitKind) -> Void)?
  ) {
    self.request = request
    self.unblock = unblock
    self.syncModel = syncModel
  }

  func finish(hidden _: Int) {
    unblock?()
    if case .adultExit(let kind) = request {
      syncModel?(kind)
    }
  }
}

private let teardownDoneTrampoline: BabyWorkTeardownDone = { hidden, context in
  guard let context else { return }
  let box = Unmanaged<TeardownDoneBox>.fromOpaque(context).takeRetainedValue()
  box.finish(hidden: Int(hidden))
}
