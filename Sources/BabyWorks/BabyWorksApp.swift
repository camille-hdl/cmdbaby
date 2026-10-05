import AppKit
import BabyWorkDiagnosticsKit
import OSLog

private let appLogger = Logger(subsystem: "fr.camille.babywork", category: "App")

@main
enum BabyWorksMain {
  static func main() {
    LifecycleLogRecorder.shared.installStandardSinks()
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
  private let model: DiagnosticsSessionModel
  private let languageAtLaunch: AppLanguagePreference
  private var statusItem: NSStatusItem?
  private lazy var settingsWindowController = SettingsWindowController(
    languageAtLaunch: languageAtLaunch,
    session: model,
    onRelaunch: { [weak self] in
      self?.relaunchApplyingLanguage()
    },
    onLaunch: { [weak self] in
      self?.launchFromSettings()
    }
  )

  override init() {
    languageAtLaunch = AppLanguageSettings(store: UserDefaultsAppLanguageStore()).current()
    model = DiagnosticsSessionModel()
    super.init()
  }

  /// « Lancer » sur une carte : ferme les Réglages, puis le même départ que le menu.
  private func launchFromSettings() {
    settingsWindowController.hide()
    model.startKiosk()
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
    applyLaunchPlan()
  }

  /// Premier lancement : enregistrer les défauts, puis ouvrir Sorties.
  /// `--open-settings general` ouvre Général sans réécrire une configuration déjà là.
  private func applyLaunchPlan() {
    let store = BabyWorksConfigurationStore()
    switch LaunchPlan.atLaunch(
      hasSavedConfiguration: store.hasSavedConfiguration,
      arguments: CommandLine.arguments
    ) {
    case .idle:
      break
    case .openSettings(let section):
      if !store.hasSavedConfiguration {
        do {
          try store.save(store.load())
        } catch {
          appLogger.error(
            "Impossible d’enregistrer la configuration par défaut : \(error.localizedDescription, privacy: .public)"
          )
        }
      }
      openSettings(section: SettingsSection(section))
    }
  }

  /// Nouvelle instance avec les Réglages sur Général, puis on quitte celle-ci.
  /// Les arguments sont ignorés si l’app est sandboxée.
  private func relaunchApplyingLanguage() {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    configuration.arguments = LaunchPlan.openGeneralSettingsArguments
    NSWorkspace.shared.openApplication(
      at: Bundle.main.bundleURL,
      configuration: configuration
    ) { app, error in
      if let error {
        appLogger.error(
          "Impossible de relancer BabyWorks : \(error.localizedDescription, privacy: .public)"
        )
        return
      }
      guard app != nil else {
        appLogger.error("Impossible de relancer BabyWorks : instance absente")
        return
      }
      Task { @MainActor in
        NSApp.terminate(nil)
      }
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    let blocked = model.isTerminationBlocked
    let reply: LifecycleLog.TerminateReply = blocked ? .cancel : .now
    LifecycleLogRecorder.shared.emit(.applicationShouldTerminate(reply: reply))
    if !blocked {
      LifecycleLogRecorder.shared.emit(.statusItemAlive(statusItem != nil))
    }
    return blocked ? .terminateCancel : .terminateNow
  }

  /// Chemin Quitter explicite : même démontage que la sortie adulte, puis `terminate:`.
  @objc func quitApplication(_ sender: Any?) {
    LifecycleLogRecorder.shared.emit(.terminateRequest)
    model.quit()
  }

  /// Lancer session : kiosque lazy (scène, filtre, couvertures) avec le mode config.
  @objc func startSession(_ sender: Any?) {
    model.startKiosk()
  }

  /// Menu « Réglages… » : toujours Mode de jeu, en attendant la fin du menu.
  @objc func openSettings(_ sender: Any?) {
    if let item = sender as? NSMenuItem {
      settingsWindowController.show(fromStatusItemMenu: true, trackingMenu: item.menu)
    } else {
      openSettings(section: .mode)
    }
  }

  /// Ouvre les Réglages sur une section. Hors menu : pas d’attente de tracking.
  private func openSettings(section: SettingsSection) {
    settingsWindowController.show(fromStatusItemMenu: false, section: section)
  }

  private func presentActivationFailure(_ error: KioskSessionError) {
    LifecycleLogRecorder.shared.emit(
      SessionActivationAlert.activationFailureLog(
        error,
        binaryPath: Bundle.main.bundleURL.path
      )
    )
    let spec = SessionActivationAlert.forFailedActivation(error)
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = spec.title
    alert.informativeText = spec.informativeText
    for action in spec.actions {
      alert.addButton(withTitle: action.title())
    }
    activateApp()
    let response = alert.runModal()
    let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
    guard spec.actions.indices.contains(index) else { return }
    switch spec.actions[index] {
    case .openAppSettings(let section):
      openSettings(section: SettingsSection(section))
    case .dismiss:
      break
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
      withTitle: L10n.current("menu.quitApplication"),
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
      accessibilityDescription: L10n.current("menu.statusIcon.accessibility")
    )
    image?.isTemplate = MenuBarAgent.usesTemplateImage
    item.button?.image = image

    let menu = NSMenu()
    for spec in MenuBarAgent.items() {
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
    LifecycleLogRecorder.shared.emit(.statusItemCreate)
  }

  func isStatusItemInstalled() -> Bool {
    statusItem != nil
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

extension SettingsSection {
  fileprivate init(_ section: InitialSettingsSection) {
    switch section {
    case .mode:
      self = .mode
    case .exits:
      self = .exits
    case .general:
      self = .general
    case .permissions:
      self = .permissions
    }
  }
}

extension MenuBarAgent.ActivationPolicy {
  @MainActor
  func apply(to app: NSApplication) {
    let before = app.activationPolicy().lifecycleLogName
    switch self {
    case .accessory:
      app.setActivationPolicy(.accessory)
    case .regular:
      app.setActivationPolicy(.regular)
    }
    LifecycleLogRecorder.shared.emit(
      .activationPolicy(before: before, after: app.activationPolicy().lifecycleLogName)
    )
  }
}

extension NSApplication.ActivationPolicy {
  fileprivate var lifecycleLogName: String {
    switch self {
    case .regular:
      "regular"
    case .accessory:
      "accessory"
    case .prohibited:
      "prohibited"
    @unknown default:
      "unknown"
    }
  }
}
