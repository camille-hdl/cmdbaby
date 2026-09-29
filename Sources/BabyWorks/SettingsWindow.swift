import AppKit
import BabyWorkDiagnosticsKit
import OSLog
import SwiftUI

private let settingsLogger = Logger(subsystem: "fr.camille.babywork", category: "Settings")

@MainActor
final class SettingsModeModel: ObservableObject {
  private let choice: SettingsModeChoice
  @Published private(set) var selectedMode: KioskPlayModeID
  let options: [KioskPlayModeID]

  init(choice: SettingsModeChoice) {
    self.choice = choice
    self.options = choice.options
    self.selectedMode = choice.selectedMode()
  }

  func select(_ mode: KioskPlayModeID) {
    do {
      try choice.select(mode)
      selectedMode = mode
    } catch {
      settingsLogger.error(
        "Impossible d’enregistrer le mode : \(error.localizedDescription, privacy: .public)"
      )
    }
  }
}

@MainActor
final class SettingsLaunchAtLoginModel: ObservableObject {
  private let choice: SettingsLaunchAtLogin
  @Published private(set) var isEnabled: Bool

  init(choice: SettingsLaunchAtLogin) {
    self.choice = choice
    self.isEnabled = choice.isEnabled()
  }

  func setEnabled(_ enabled: Bool) {
    do {
      try choice.setEnabled(enabled)
      isEnabled = choice.isEnabled()
    } catch {
      isEnabled = choice.isEnabled()
      settingsLogger.error(
        "Impossible d’enregistrer le démarrage automatique : \(error.localizedDescription, privacy: .public)"
      )
    }
  }
}

struct SettingsView: View {
  @ObservedObject var model: SettingsModeModel
  @ObservedObject var launchAtLogin: SettingsLaunchAtLoginModel

  var body: some View {
    Form {
      Picker(
        "Mode",
        selection: Binding(
          get: { model.selectedMode },
          set: { model.select($0) }
        )
      ) {
        ForEach(model.options, id: \.self) { mode in
          Text(KioskPlayModeCatalog.displayName(mode)).tag(mode)
        }
      }
      .pickerStyle(.radioGroup)

      Toggle(
        "Démarrage automatique",
        isOn: Binding(
          get: { launchAtLogin.isEnabled },
          set: { launchAtLogin.setEnabled($0) }
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
  private var model: SettingsModeModel?
  private var launchAtLoginModel: SettingsLaunchAtLoginModel?
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
    let model = SettingsModeModel(choice: SettingsModeChoice(store: store))
    let launchAtLoginModel = SettingsLaunchAtLoginModel(
      choice: SettingsLaunchAtLogin(store: store, loginItem: loginItem)
    )
    self.model = model
    self.launchAtLoginModel = launchAtLoginModel
    let window = existingOrMakeWindow()
    window.contentView = NSHostingView(
      rootView: SettingsView(model: model, launchAtLogin: launchAtLoginModel)
    )
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
      observeAfterOrderFront(isRetry: sequence.orderFrontIsRetry) { [weak self] in
        guard let self, self.showGeneration == generation else { return }
        guard var sequence = self.showSequence else { return }
        let visible = self.window?.isVisible == true
        let key = self.window?.isKeyWindow == true
        let event = sequence.recordOrderFront(isVisible: visible, isKeyWindow: key)
        self.showSequence = sequence
        self.log.emit(event)
        if sequence.shouldOrderFront {
          self.continueShow()
        }
      }
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

  private func observeAfterOrderFront(
    isRetry: Bool,
    then work: @escaping @MainActor () -> Void
  ) {
    if isRetry {
      performAfterOrderFrontRetry(work)
    } else {
      performAfterCurrentTracking(work)
    }
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
    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    window.delegate = self
    window.center()
    self.window = window
    return window
  }
}
