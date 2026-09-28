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
final class SettingsWindowController {
  private let store: BabyWorksConfigurationStore
  private let loginItem: any LoginItemRegistration
  private var window: NSWindow?
  private var model: SettingsModeModel?
  private var launchAtLoginModel: SettingsLaunchAtLoginModel?

  init(
    store: BabyWorksConfigurationStore = BabyWorksConfigurationStore(),
    loginItem: any LoginItemRegistration = SMAppServiceLoginItem()
  ) {
    self.store = store
    self.loginItem = loginItem
  }

  func show() {
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
    window.makeKeyAndOrderFront(nil)
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
    window.center()
    self.window = window
    return window
  }
}
