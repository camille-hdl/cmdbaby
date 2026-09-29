import AppKit
import ApplicationServices
import BabyWorkDiagnosticsKit

@main
enum BabyWorksMain {
  static func main() {
    let app = NSApplication.shared
    let delegate = MainActor.assumeIsolated {
      MenuBarAgent.activationPolicy.apply(to: app)
      return BabyWorksAppDelegate()
    }
    app.delegate = delegate
    withExtendedLifetime(delegate) {
      app.run()
    }
  }
}

@MainActor
final class BabyWorksAppDelegate: NSObject, NSApplicationDelegate {
  private let terminationGate: TerminationGate
  private let model: DiagnosticsSessionModel
  private var statusItem: NSStatusItem?
  private let settingsWindowController = SettingsWindowController()

  override init() {
    let gate = TerminationGate()
    terminationGate = gate
    model = DiagnosticsSessionModel(terminationGate: gate)
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    installMainMenu()
    installStatusItem()
    model.attachTerminationDelegate(self)
    model.attachParentChrome(
      hide: { [weak self] in self?.settingsWindowController.hide() },
      presentActivationFailure: { [weak self] error in
        self?.presentActivationFailure(error)
      }
    )
  }

  nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  nonisolated func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    terminationGate.isBlocked() ? .terminateCancel : .terminateNow
  }

  /// Chemin Quitter explicite : même démontage que la sortie adulte, puis `terminate:`.
  @objc func quitApplication(_ sender: Any?) {
    model.quit()
  }

  /// Lancer session : kiosque lazy (scène, filtre, couvertures) avec le mode config.
  @objc func startSession(_ sender: Any?) {
    model.startKiosk()
  }

  /// Réglages : fenêtre native avec le choix du mode.
  @objc func openSettings(_ sender: Any?) {
    settingsWindowController.show(fromStatusItemMenu: sender is NSMenuItem)
  }

  private func presentActivationFailure(_ error: KioskSessionError) {
    let spec = SessionActivationAlert.forFailedActivation(
      error,
      runningBinaryURL: Bundle.main.bundleURL
    )
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = spec.title
    alert.informativeText = spec.informativeText
    for action in spec.actions {
      alert.addButton(withTitle: action.title)
    }
    activateApp()
    let response = alert.runModal()
    let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
    guard spec.actions.indices.contains(index) else { return }
    switch spec.actions[index] {
    case .openAccessibilitySettings:
      openAccessibilitySettings()
    case .openAppSettings:
      openSettings(nil)
    case .dismiss:
      break
    }
  }

  private func openAccessibilitySettings() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    for candidate in SessionActivationAlert.accessibilitySettingsURLCandidates {
      if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
        return
      }
    }
  }

  private func activateApp() {
    if #available(macOS 14, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func installMainMenu() {
    let mainMenu = NSMenu()
    let appItem = NSMenuItem()
    mainMenu.addItem(appItem)
    let appMenu = NSMenu(title: "BabyWorks")
    appMenu.addItem(
      withTitle: "Quitter BabyWorks",
      action: #selector(quitApplication(_:)),
      keyEquivalent: "q"
    )
    appItem.submenu = appMenu
    NSApp.mainMenu = mainMenu
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let image = NSImage(
      systemSymbolName: MenuBarAgent.systemSymbolName,
      accessibilityDescription: "BabyWorks"
    )
    image?.isTemplate = MenuBarAgent.usesTemplateImage
    item.button?.image = image

    let menu = NSMenu()
    for spec in MenuBarAgent.items {
      let menuItem = NSMenuItem(
        title: spec.title,
        action: selector(for: spec.action),
        keyEquivalent: ""
      )
      menuItem.target = self
      menu.addItem(menuItem)
    }
    item.menu = menu
    statusItem = item
  }

  private func selector(for action: MenuBarAgent.Action) -> Selector {
    switch action {
    case .startSession:
      #selector(startSession(_:))
    case .openSettings:
      #selector(openSettings(_:))
    case .terminate:
      #selector(quitApplication(_:))
    }
  }
}

extension MenuBarAgent.ActivationPolicy {
  @MainActor
  func apply(to app: NSApplication) {
    switch self {
    case .accessory:
      app.setActivationPolicy(.accessory)
    case .regular:
      app.setActivationPolicy(.regular)
    }
  }
}
