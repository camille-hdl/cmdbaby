import AppKit
import BabyWorkDiagnosticsKit
import OSLog
import SwiftUI

private let settingsLogger = Logger(subsystem: "fr.camille.babywork", category: "Settings")

@MainActor
final class SettingsModel: ObservableObject {
  private let settings: BabyWorksSettings
  @Published private(set) var configuration: BabyWorksConfiguration
  @Published private(set) var lastError: String?

  init(settings: BabyWorksSettings) {
    self.settings = settings
    self.configuration = settings.current()
  }

  func apply(_ change: SettingsChange) {
    do {
      configuration = try settings.apply(change)
      lastError = nil
    } catch {
      switch change {
      case .mode:
        settingsLogger.error(
          "Impossible d’enregistrer le mode : \(error.localizedDescription, privacy: .public)"
        )
      case .launchAtLogin:
        settingsLogger.error(
          "Impossible d’enregistrer le démarrage automatique : \(error.localizedDescription, privacy: .public)"
        )
      }
      lastError = error.localizedDescription
      configuration = settings.current()
    }
  }
}

struct SettingsView: View {
  @ObservedObject var model: SettingsModel

  var body: some View {
    Form {
      Picker(
        "Mode",
        selection: Binding(
          get: { model.configuration.mode },
          set: { model.apply(.mode($0)) }
        )
      ) {
        ForEach(KioskPlayModeCatalog.available, id: \.self) { mode in
          Text(KioskPlayModeCatalog.displayName(mode)).tag(mode)
        }
      }
      .pickerStyle(.radioGroup)

      Toggle(
        "Démarrage automatique",
        isOn: Binding(
          get: { model.configuration.launchAtLogin },
          set: { model.apply(.launchAtLogin($0)) }
        )
      )
      .help("Ouvre BabyWorks dans la barre de menus au login, sans lancer de session.")
    }
    .padding(20)
    .frame(minWidth: 280, minHeight: 120)
  }
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
  private let store: BabyWorksConfigurationStore
  private let loginItem: any LoginItemRegistration
  private let log: LifecycleLogRecorder
  private var window: NSWindow?
  private var model: SettingsModel?
  private var showSequence: SettingsShowSequence?
  private var showGeneration = 0
  private var trackingMenu: NSMenu?
  private var waitingForMenuTracking = false
  private var menuTrackingProceed: (@MainActor () -> Void)?

  init(
    store: BabyWorksConfigurationStore = BabyWorksConfigurationStore(),
    loginItem: any LoginItemRegistration = SMAppServiceLoginItem(),
    log: LifecycleLogRecorder = .shared
  ) {
    self.store = store
    self.loginItem = loginItem
    self.log = log
    super.init()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func show(fromStatusItemMenu: Bool = true, trackingMenu: NSMenu? = nil) {
    cancelPendingShow()
    log.emit(.settingsShowRequest)
    let model = SettingsModel(
      settings: BabyWorksSettings(store: store, loginItem: loginItem)
    )
    self.model = model
    let window = existingOrMakeWindow()
    window.contentView = NSHostingView(rootView: SettingsView(model: model))
    self.trackingMenu = trackingMenu
    showSequence = SettingsShowSequence(fromStatusItemMenu: fromStatusItemMenu)
    continueShow()
  }

  func hide() {
    cancelPendingShow()
    restoreWindowAfterHiding()
    window?.orderOut(nil)
    restoreActivationPolicy()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    hide()
    return false
  }

  private func restoreActivationPolicy() {
    SettingsWindowPresentation.activationPolicyAfterHiding(
      otherParentUIVisible: isOtherParentUIVisible()
    ).apply(to: NSApp)
  }

  private func isOtherParentUIVisible() -> Bool {
    NSApp.windows.contains { candidate in
      candidate !== window && candidate.isVisible && candidate.styleMask.contains(.titled)
    }
  }

  private func continueShow() {
    let generation = showGeneration
    guard let sequence = showSequence else { return }

    if sequence.shouldWaitForMenuTracking {
      waitForMenuTrackingToEnd { [weak self] in
        guard let self, self.showGeneration == generation else { return }
        self.mutateSequence { $0.menuTrackingDidEnd() }
        self.continueShow()
      }
      return
    }

    if sequence.shouldApplyVisibleActivationPolicy {
      SettingsWindowPresentation.visibleActivationPolicy.apply(to: NSApp)
    }

    if sequence.shouldOrderFront {
      orderFrontAndActivate()
      if sequence.orderFrontIsRetry {
        performAfterOrderFrontRetry { [weak self] in
          self?.finishOrderFrontObservation(generation: generation)
        }
      } else {
        performAfterCurrentTracking { [weak self] in
          self?.finishOrderFrontObservation(generation: generation)
        }
      }
    }
  }

  private func finishOrderFrontObservation(generation: Int) {
    guard showGeneration == generation else { return }
    guard var sequence = showSequence else { return }
    let visible = window?.isVisible == true
    let key = window?.isKeyWindow == true
    let event = sequence.recordOrderFront(isVisible: visible, isKeyWindow: key)
    showSequence = sequence
    log.emit(event)
    if sequence.shouldOrderFront {
      continueShow()
    }
  }

  @discardableResult
  private func mutateSequence(_ body: (inout SettingsShowSequence) -> Void) -> SettingsShowSequence? {
    guard var sequence = showSequence else { return nil }
    body(&sequence)
    showSequence = sequence
    return sequence
  }

  private func cancelPendingShow() {
    showGeneration += 1
    stopObservingMenuTracking()
    menuTrackingProceed = nil
    trackingMenu = nil
  }

  private func waitForMenuTrackingToEnd(then proceed: @escaping @MainActor () -> Void) {
    let generation = showGeneration
    waitingForMenuTracking = true
    menuTrackingProceed = proceed
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMenuDidEndTracking(_:)),
      name: NSMenu.didEndTrackingNotification,
      object: trackingMenu
    )
    performAfterCurrentTracking { [weak self] in
      guard let self, self.showGeneration == generation else { return }
      self.finishWaitingForMenuTracking()
    }
  }

  @objc private func handleMenuDidEndTracking(_ notification: Notification) {
    finishWaitingForMenuTracking()
  }

  private func finishWaitingForMenuTracking() {
    guard waitingForMenuTracking else { return }
    let proceed = menuTrackingProceed
    stopObservingMenuTracking()
    menuTrackingProceed = nil
    proceed?()
  }

  private func stopObservingMenuTracking() {
    guard waitingForMenuTracking else { return }
    NotificationCenter.default.removeObserver(
      self,
      name: NSMenu.didEndTrackingNotification,
      object: trackingMenu
    )
    waitingForMenuTracking = false
  }

  /// Entre deux tentatives : laisser à AppKit le temps de prendre le key.
  private func performAfterOrderFrontRetry(_ work: @escaping @MainActor () -> Void) {
    let generation = showGeneration
    DispatchQueue.main.asyncAfter(
      deadline: .now() + SettingsWindowPresentation.orderFrontRetryDelay
    ) { [weak self] in
      DispatchQueue.main.async {
        guard let self, self.showGeneration == generation else { return }
        work()
      }
    }
  }

  /// Après le tracking menu : le mode par défaut ne tourne qu’une fois le run loop imbriqué fini.
  private func performAfterCurrentTracking(_ work: @escaping @MainActor () -> Void) {
    let generation = showGeneration
    CFRunLoopPerformBlock(
      CFRunLoopGetMain(),
      CFRunLoopMode.defaultMode.rawValue as CFString
    ) { [weak self] in
      DispatchQueue.main.async {
        guard let self, self.showGeneration == generation else { return }
        work()
      }
    }
    CFRunLoopWakeUp(CFRunLoopGetMain())
  }

  private func orderFrontAndActivate() {
    guard let window else { return }
    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    window.level = .floating
    activateApp()
    window.makeKeyAndOrderFront(nil)
  }

  private func restoreWindowAfterHiding() {
    window?.level = .normal
    window?.collectionBehavior = []
  }

  private func activateApp() {
    if #available(macOS 14, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func existingOrMakeWindow() -> NSWindow {
    if let window {
      return window
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = "Réglages"
    window.identifier = NSUserInterfaceItemIdentifier("fr.camille.babywork.settings")
    window.isReleasedWhenClosed = false
    window.delegate = self
    window.center()
    self.window = window
    return window
  }
}
