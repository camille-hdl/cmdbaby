import AppKit
import BabyWorkDiagnosticsKit
import SwiftUI

@main
enum BabyWorksMain {
  static func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    let delegate = MainActor.assumeIsolated { BabyWorksAppDelegate() }
    app.delegate = delegate
    withExtendedLifetime(delegate) {
      app.run()
    }
  }
}

/// Actions destinées aux vues SwiftUI : aucun type isolé MainActor n’est capturé.
struct DiagnosticActions: Sendable {
  var refresh: @Sendable () -> Void
  var toggleFilter: @Sendable () -> Void
  var requestAccessibility: @Sendable () -> Void
  var relaunch: @Sendable () -> Void
  var revealInFinder: @Sendable () -> Void
  var reenableFilter: @Sendable () -> Void
  var setInjectedFailure: @Sendable (FailureInjectionChoice) -> Void
  var startKiosk: @Sendable (FailureInjectionChoice) -> Void
}

@MainActor
final class BabyWorksAppDelegate: NSObject, NSApplicationDelegate {
  private let terminationGate: TerminationGate
  private let revealPump = DiagnosticRevealPump()
  private let model: DiagnosticsSessionModel
  private var diagnosticWindow: NSWindow?
  private var hostingView: NSView?

  override init() {
    let gate = TerminationGate()
    terminationGate = gate
    model = DiagnosticsSessionModel(terminationGate: gate)
    super.init()
  }

  func makeActions() -> DiagnosticActions {
    let model = self.model
    return DiagnosticActions(
      refresh: { Task { @MainActor in model.refresh() } },
      toggleFilter: { Task { @MainActor in model.toggleFilter() } },
      requestAccessibility: { Task { @MainActor in model.requestAccessibilityPrompt() } },
      relaunch: { Task { @MainActor in model.relaunch() } },
      revealInFinder: { Task { @MainActor in model.revealAppInFinder() } },
      reenableFilter: { Task { @MainActor in model.reenableFilter() } },
      setInjectedFailure: { choice in
        Task { @MainActor in model.setInjectedFailure(choice) }
      },
      startKiosk: { choice in
        Task { @MainActor in model.startKiosk(injected: choice) }
      }
    )
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    installMainMenu()
    model.attachTerminationDelegate(self)
    model.attachDiagnosticWindow(
      hide: { [weak self] in self?.detachDiagnosticView() },
      reveal: { [weak self] in self?.attachDiagnosticView() }
    )

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 780, height: 900),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "BabyWorks"
    window.identifier = NSUserInterfaceItemIdentifier("fr.camille.babywork.parent")
    window.isReleasedWhenClosed = false
    window.center()
    diagnosticWindow = window
    revealPump.attach(window: window) {}
    model.attachRevealPump(revealPump)
    model.startKiosk(injected: .none)
  }

  nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  nonisolated func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    terminationGate.isBlocked() ? .terminateCancel : .terminateNow
  }

  /// Détruit le graphe SwiftUI avant le kiosque. Réaffiché seulement si l’activation échoue.
  private func detachDiagnosticView() {
    diagnosticWindow?.contentView = NSView(frame: .zero)
    diagnosticWindow?.orderOut(nil)
    hostingView = nil
  }

  private func attachDiagnosticView() {
    hostingView = nil
    let hosting = NSHostingView(rootView: DiagnosticView(ui: model.ui, actions: makeActions()))
    hostingView = hosting
    diagnosticWindow?.contentView = hosting
    diagnosticWindow?.makeKeyAndOrderFront(nil)
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
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    appItem.submenu = appMenu
    NSApp.mainMenu = mainMenu
  }
}

private struct DiagnosticView: View {
  @ObservedObject var ui: DiagnosticsPublishedState
  let actions: DiagnosticActions

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        ForEach(ui.report.sections.indices, id: \.self) { sectionIndex in
          let section = ui.report.sections[sectionIndex]
          DiagnosticSectionView(section: section)
        }

        InputFilterPanel(ui: ui, actions: actions)
        KioskPanel(ui: ui, actions: actions)
      }
      .padding(28)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .onReceive(
      NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
    ) { _ in
      guard !ui.isKioskActive else { return }
      actions.refresh()
    }
    .toolbar {
      Button("Actualiser", systemImage: "arrow.clockwise") {
        actions.refresh()
      }
      .help("Relire les informations système et les permissions")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Outils parents")
        .font(.largeTitle.bold())
      Text("Cette fenêtre n’apparaît que si le mode plein écran ne peut pas démarrer.")
        .font(.title3)
        .foregroundStyle(.secondary)
      Text("Les frappes ne sont jamais journalisées ni persistées. Seuls des compteurs de raccourcis absorbés sont affichés.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }
}

private struct InputFilterPanel: View {
  @ObservedObject var ui: DiagnosticsPublishedState
  let actions: DiagnosticActions

  var body: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 16) {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
          GridRow {
            Text("État du filtre")
              .fontWeight(.medium)
            Text(ui.filterStatus.displayName)
              .textSelection(.enabled)
          }
          GridRow {
            Text("Sandbox App")
              .fontWeight(.medium)
            Text(sandboxLabel)
              .textSelection(.enabled)
          }
        }

        HStack(spacing: 12) {
          Button(ui.isFilterActive ? "Désactiver le filtre" : "Activer le filtre") {
            actions.toggleFilter()
          }
          .disabled(ui.isKioskActive)

          Button("Demander Accessibilité") {
            actions.requestAccessibility()
          }

          Button("Quitter et relancer") {
            actions.relaunch()
          }

          Button("Afficher dans le Finder") {
            actions.revealInFinder()
          }

          if case .disabledByTimeout = ui.filterStatus {
            Button("Réactiver le tap") {
              actions.reenableFilter()
            }
          }
          if case .disabledByUserInput = ui.filterStatus {
            Button("Réactiver le tap") {
              actions.reenableFilter()
            }
          }
        }

        Text("Le filtre actif dépend d’Accessibilité, pas de Surveillance de l’entrée. Après avoir coché BabyWorks dans Accessibilité, macOS mémorise « non » jusqu’à la relance : utilisez Quitter et relancer, pas Actualiser. Si la ligne n’existe pas, glissez l’app depuis le Finder sur la liste, ou ajoutez-la avec +.")
          .font(.callout)
          .foregroundStyle(.secondary)

        Text("Sorties adultes : parent + Entrée, ou Majuscule-Échap. Elles quittent l’application après restauration de la présentation. Commande-Q est absorbé pendant le kiosque.")
          .font(.callout)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(MonitoredShortcut.allCases, id: \.self) { shortcut in
            HStack {
              Text(shortcut.displayName)
              Spacer()
              Text("\(ui.count(for: shortcut))")
                .monospacedDigit()
                .foregroundStyle(ui.count(for: shortcut) > 0 ? Color.green : Color.secondary)
            }
          }
        }
      }
      .padding(4)
    } label: {
      Text("Filtrage actif (CGEventTap de session)")
        .font(.headline)
    }
  }

  private var sandboxLabel: String {
    if let label = Bundle.main.object(forInfoDictionaryKey: "BabyWorkSandboxMode") as? String,
      !label.isEmpty
    {
      return label
    }
    if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
      return "Conteneur détecté à l’exécution"
    }
    return "Non détecté à l’exécution"
  }
}

private struct KioskPanel: View {
  @ObservedObject var ui: DiagnosticsPublishedState
  let actions: DiagnosticActions

  var body: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 16) {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
          GridRow {
            Text("État du kiosque")
              .fontWeight(.medium)
            Text(ui.kioskState.phase.displayName)
              .textSelection(.enabled)
          }
          GridRow {
            Text("Écrans couverts")
              .fontWeight(.medium)
            Text(coveredScreensLabel)
              .textSelection(.enabled)
          }
          GridRow {
            Text("Dernière sortie")
              .fontWeight(.medium)
            Text(exitLabel)
              .textSelection(.enabled)
          }
          if let error = ui.kioskState.lastError {
            GridRow {
              Text("Dernier échec")
                .fontWeight(.medium)
              Text(error.localizedDescription)
                .textSelection(.enabled)
            }
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Simuler une défaillance : \(ui.injectedFailureChoice.displayName)")
            .fontWeight(.medium)
          ForEach(FailureInjectionChoice.allCases) { choice in
            Button(choice.displayName) {
              ui.injectedFailureChoice = choice
            }
            .disabled(ui.isKioskActive)
            .opacity(ui.injectedFailureChoice == choice ? 1 : 0.55)
          }
        }

        Button(ui.isKioskActive ? "Kiosque actif…" : "Activer le kiosque") {
          actions.startKiosk(ui.injectedFailureChoice)
        }
        .disabled(ui.isKioskActive)

        Text("Le kiosque démarre à l’ouverture. Cette fenêtre n’apparaît que si l’activation échoue (Accessibilité, défaillance simulée). Commande-Q est absorbé pendant le kiosque. Une sortie adulte (parent + Entrée, Majuscule-Échap, 5 clics sur le carré pâle, ou \(Int(SessionTimeLimit.defaultDuration / 60)) minutes) restaure la présentation puis quitte l’application.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      .padding(4)
    } label: {
      Text("Confinement multi-écrans")
        .font(.headline)
    }
  }

  private var coveredScreensLabel: String {
    let screens = ui.kioskState.coveredScreens
    if screens.isEmpty {
      return ui.kioskState.phase == .active ? "Aucun" : "—"
    }
    return screens.map { screen in
      let origin = "(\(Int(screen.originX.rounded())), \(Int(screen.originY.rounded())))"
      return "\(screen.name) \(origin)"
    }.joined(separator: " · ")
  }

  private var exitLabel: String {
    switch ui.kioskState.lastExitKind {
    case .passphrase:
      "Séquence parent + Entrée"
    case .shiftEscape:
      "Majuscule-Échap"
    case .failsafeClick:
      "Clics de secours"
    case .timeLimit:
      "Minuteur"
    case nil:
      "—"
    }
  }
}

private struct DiagnosticSectionView: View {
  let section: DiagnosticSection

  var body: some View {
    GroupBox {
      Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
        ForEach(section.rows.indices, id: \.self) { rowIndex in
          let row = section.rows[rowIndex]
          let presentation = row.state.presentation
          GridRow {
            Label {
              Text(row.label)
                .fontWeight(.medium)
            } icon: {
              Image(systemName: presentation.symbolName)
                .foregroundStyle(presentation.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.value)
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .padding(4)
    } label: {
      Text(section.title)
        .font(.headline)
    }
  }
}

extension DiagnosticRowState {
  fileprivate var presentation: (symbolName: String, color: Color) {
    switch self {
    case .neutral:
      ("info.circle", .secondary)
    case .granted:
      ("checkmark.circle.fill", .green)
    case .attention:
      ("exclamationmark.triangle.fill", .orange)
    }
  }
}
