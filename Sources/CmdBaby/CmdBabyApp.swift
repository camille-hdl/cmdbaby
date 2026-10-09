import AppKit
import CmdBabyKit
import OSLog

private let appLogger = Logger(subsystem: AppIdentity.logSubsystem, category: "App")

@main
enum CmdBabyMain {
  static func main() {
    LifecycleLogRecorder.shared.installStandardSinks()
    let store = CmdBabyConfigurationStore()
    store.migrateLegacyConfiguration()
    store.restrictPermissions()
    let app = NSApplication.shared
    let delegate = MainActor.assumeIsolated {
      MenuBarAgent.activationPolicy.apply(to: app)
      return CmdBabyAppDelegate()
    }
    app.delegate = delegate
    withExtendedLifetime(delegate) {
      app.run()
    }
  }
}

@MainActor
final class CmdBabyAppDelegate: NSObject, NSApplicationDelegate {
  /// Délégué de l’app qui tourne, pour l’action Raccourcis. Posé dès `init`.
  static weak var running: CmdBabyAppDelegate?

  private let model: DiagnosticsSessionModel
  private let updates: UpdateController
  private let languageAtLaunch: AppLanguagePreference
  private var statusItem: NSStatusItem?
  private lazy var settingsWindowController = SettingsWindowController(
    languageAtLaunch: languageAtLaunch,
    session: model,
    updates: updates,
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
    updates = UpdateController(session: model)
    super.init()
    Self.running = self
  }

  /// « Lancer » sur une carte : ferme les Réglages, puis le même départ que le menu.
  private func launchFromSettings() {
    settingsWindowController.hide()
    model.startKiosk()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    #if DEBUG
    if let snapshot = SettingsSnapshotRequest(arguments: CommandLine.arguments) {
      settingsWindowController.writeSnapshot(section: snapshot.section, dark: snapshot.dark, to: snapshot.url) {
        exit(0)
      }
      return
    }
    #endif
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
    let store = CmdBabyConfigurationStore()
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
          "Impossible de relancer \(AppIdentity.displayName, privacy: .public) : \(error.localizedDescription, privacy: .public)"
        )
        return
      }
      guard app != nil else {
        appLogger.error(
          "Impossible de relancer \(AppIdentity.displayName, privacy: .public) : instance absente"
        )
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
        binaryPath: LifecycleLog.displayPath(Bundle.main.bundleURL.path)
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

  /// Menus de l’app et Édition, traduits depuis `MenuBarAgent`.
  private func installMainMenu() {
    let mainMenu = NSMenu()
    for (title, entries) in [
      (AppIdentity.displayName, MenuBarAgent.applicationMenu),
      (L10n.current(MenuBarAgent.editMenuTitleKey), MenuBarAgent.editMenu),
    ] {
      let submenu = NSMenu(title: title)
      for entry in entries {
        submenu.addItem(menuItem(entry))
      }
      let item = NSMenuItem()
      item.submenu = submenu
      mainMenu.addItem(item)
    }
    NSApp.mainMenu = mainMenu
  }

  private func menuItem(_ entry: MenuBarAgent.MenuEntry) -> NSMenuItem {
    guard entry.command != .separator else { return .separator() }
    let (action, target) = mainMenuAction(entry.command)
    let item = NSMenuItem(
      title: L10n.current(entry.titleKey),
      action: action,
      keyEquivalent: entry.keyEquivalent
    )
    item.keyEquivalentModifierMask = NSEvent.ModifierFlags(entry.modifiers)
    item.target = target
    item.isHidden = entry.command == .checkForUpdates && !updates.isAvailable
    return item
  }

  /// Édition : cible `nil`, la chaîne de répondeurs trouve le champ actif.
  private func mainMenuAction(_ command: MenuBarAgent.MenuCommand) -> (Selector?, AnyObject?) {
    switch command {
    case .about: (#selector(openAboutFromMainMenu(_:)), self)
    case .checkForUpdates: (#selector(UpdateController.checkForUpdates(_:)), updates)
    case .settings: (#selector(openSettingsFromMainMenu(_:)), self)
    case .hide: (#selector(NSApplication.hide(_:)), NSApp)
    case .hideOthers: (#selector(NSApplication.hideOtherApplications(_:)), NSApp)
    case .showAll: (#selector(NSApplication.unhideAllApplications(_:)), NSApp)
    case .quit: (#selector(quitApplication(_:)), self)
    case .undo: (Selector(("undo:")), nil)
    case .redo: (Selector(("redo:")), nil)
    case .cut: (#selector(NSText.cut(_:)), nil)
    case .copy: (#selector(NSText.copy(_:)), nil)
    case .paste: (#selector(NSText.paste(_:)), nil)
    case .selectAll: (#selector(NSText.selectAll(_:)), nil)
    case .separator: (nil, nil)
    }
  }

  /// Menu de l’app « Réglages… » (⌘,) : Mode de jeu, sans attendre de menu de la barre d’état.
  @objc func openSettingsFromMainMenu(_ sender: Any?) {
    openSettings(section: .mode)
  }

  @objc func openAboutFromMainMenu(_ sender: Any?) {
    openSettings(section: .about)
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = Self.statusIcon()

    let menu = NSMenu()
    for spec in MenuBarAgent.items() {
      let menuItem = NSMenuItem(
        title: spec.title,
        action: selector(for: spec.action),
        keyEquivalent: spec.keyEquivalent
      )
      menuItem.target = self
      menu.addItem(menuItem)
    }
    item.menu = menu
    statusItem = item
    LifecycleLogRecorder.shared.emit(.statusItemCreate)
  }

  /// Biberon en PDF template ; repli sur un SF Symbol si le PDF manque au bundle.
  private static func statusIcon() -> NSImage? {
    let description = L10n.current("menu.statusIcon.accessibility")
    let image: NSImage?
    if let url = MenuBarAgent.statusIconURL(), let bottle = NSImage(contentsOf: url) {
      bottle.size = MenuBarAgent.statusIconPointSize
      bottle.accessibilityDescription = description
      image = bottle
    } else {
      LifecycleLogRecorder.shared.emit(.statusIconMissing)
      image = NSImage(
        systemSymbolName: MenuBarAgent.fallbackSymbolName,
        accessibilityDescription: description
      )
    }
    image?.isTemplate = MenuBarAgent.usesTemplateImage
    return image
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

extension NSEvent.ModifierFlags {
  init(_ mask: InputModifierMask) {
    var flags: NSEvent.ModifierFlags = []
    if mask.contains(.command) { flags.insert(.command) }
    if mask.contains(.option) { flags.insert(.option) }
    if mask.contains(.control) { flags.insert(.control) }
    if mask.contains(.shift) { flags.insert(.shift) }
    self = flags
  }
}

#if DEBUG
/// `swift run CmdBaby --snapshot-settings <mode|exits|general|permissions|about> <light|dark> <fichier.png>`
struct SettingsSnapshotRequest {
  let section: SettingsSection
  let dark: Bool
  let url: URL

  init?(arguments: [String]) {
    guard let flag = arguments.firstIndex(of: "--snapshot-settings"), arguments.count > flag + 3 else {
      return nil
    }
    let sections: [String: SettingsSection] = [
      "mode": .mode, "exits": .exits, "general": .general, "permissions": .permissions, "about": .about,
    ]
    guard let section = sections[arguments[flag + 1]] else { return nil }
    self.section = section
    dark = arguments[flag + 2] == "dark"
    url = URL(fileURLWithPath: arguments[flag + 3])
  }
}
#endif
