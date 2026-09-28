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

struct SettingsView: View {
  @ObservedObject var model: SettingsModeModel

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
    }
    .padding(20)
    .frame(minWidth: 280, minHeight: 80)
  }
}

@MainActor
final class SettingsWindowController {
  private let store: BabyWorksConfigurationStore
  private var window: NSWindow?
  private var model: SettingsModeModel?

  init(store: BabyWorksConfigurationStore = BabyWorksConfigurationStore()) {
    self.store = store
  }

  func show() {
    let model = SettingsModeModel(choice: SettingsModeChoice(store: store))
    self.model = model
    let window = existingOrMakeWindow()
    window.contentView = NSHostingView(rootView: SettingsView(model: model))
    window.makeKeyAndOrderFront(nil)
    if #available(macOS 14, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  func hide() {
    window?.orderOut(nil)
  }

  private func existingOrMakeWindow() -> NSWindow {
    if let window {
      return window
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 140),
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
