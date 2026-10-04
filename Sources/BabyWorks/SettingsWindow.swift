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
      case .timeLimitMinutes:
        settingsLogger.error(
          "Impossible d’enregistrer le minuteur : \(error.localizedDescription, privacy: .public)"
        )
      case .exitMethod:
        settingsLogger.error(
          "Impossible d’enregistrer la sortie : \(error.localizedDescription, privacy: .public)"
        )
      }
      lastError = error.localizedDescription
      configuration = settings.current()
    }
  }
}

private enum SettingsWindowMetrics {
  static let width: CGFloat = 760
  static let height: CGFloat = 540
  static let sidebarWidth: CGFloat = 190
}

private struct SettingsSectionCopy {
  var title: String
  var subtitle: String
  var symbolName: String
}

private enum SettingsSection: CaseIterable, Identifiable {
  case mode
  case exits
  case general

  var id: Self { self }

  var copy: SettingsSectionCopy {
    switch self {
    case .mode:
      SettingsSectionCopy(
        title: "Mode de jeu",
        subtitle: "Choisis ce que l’enfant voit pendant la session.",
        symbolName: "sparkles"
      )
    case .exits:
      SettingsSectionCopy(
        title: "Sorties",
        subtitle: "Ce qui met fin à une session.",
        symbolName: "door.left.hand.open"
      )
    case .general:
      SettingsSectionCopy(
        title: "Général",
        subtitle: "Réglages qui s’appliquent en dehors d’une session.",
        symbolName: "gearshape"
      )
    }
  }
}

private struct ManualExitCopy: Identifiable {
  var method: AdultExitMethod
  var label: String
  var help: String

  var id: AdultExitMethod { method }
}

private let manualExitCopies: [ManualExitCopy] = [
  ManualExitCopy(
    method: .passphrase,
    label: "Phrase + Entrée",
    help: "Taper la phrase de sortie puis Entrée"
  ),
  ManualExitCopy(
    method: .shiftEscape,
    label: "Maj-Échap",
    help: "Majuscule + Échap"
  ),
  ManualExitCopy(
    method: .failsafeClick,
    label: "Clics de secours",
    help: "5 clics rapides sur le carré en bas à droite"
  ),
]

private let keepOneManualExitHelp = "Gardez au moins une sortie active."

private let timeLimitHelp =
  "Le contour du carré de secours se remplit pendant la session ; la session s’arrête quand il est complet."

private let timeLimitRejectionMessage =
  "Indique une durée entre \(AdultExitSettings.timeLimitRange.lowerBound) et \(AdultExitSettings.timeLimitRange.upperBound) minutes."

private let launchAtLoginHelp =
  "Ouvre BabyWorks dans la barre de menus au login, sans lancer de session."

struct SettingsView: View {
  @ObservedObject var model: SettingsModel
  @Environment(\.colorScheme) private var colorScheme
  @State private var section: SettingsSection = .mode
  @State private var hoveredSection: SettingsSection?
  @FocusState private var focusedSection: SettingsSection?
  @FocusState private var focusedMode: KioskPlayModeID?
  @FocusState private var timeLimitFieldFocused: Bool
  @State private var timeLimitDraft = ""
  @State private var timeLimitRejection: String?

  var body: some View {
    HStack(spacing: 0) {
      sidebar
      Rectangle()
        .fill(color(SettingsPalette.rule))
        .frame(width: 1)
      panel
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(color(SettingsPalette.paper))
    .tint(color(SettingsPalette.claret))
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("BabyWorks")
        .font(.system(size: 22, weight: .bold, design: .serif))
        .foregroundStyle(color(SettingsPalette.ink))
        .padding(.horizontal, 10)
        .padding(.bottom, 16)
      ForEach(SettingsSection.allCases) { item in
        sidebarRow(item)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.top, 40)
    .padding(.bottom, 16)
    .frame(width: SettingsWindowMetrics.sidebarWidth, alignment: .topLeading)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(color(SettingsPalette.surface1))
  }

  private func sidebarRow(_ item: SettingsSection) -> some View {
    let selected = section == item
    return Button {
      section = item
    } label: {
      HStack(spacing: 8) {
        Image(systemName: item.copy.symbolName)
          .font(.system(size: 14, weight: .medium))
          .frame(width: 20)
        Text(item.copy.title)
          .font(.system(size: 13, weight: selected ? .semibold : .regular))
        Spacer(minLength: 0)
      }
      .foregroundStyle(color(selected ? SettingsPalette.ink : SettingsPalette.ink2))
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(sidebarFill(selected: selected, hovered: hoveredSection == item))
      )
    }
    .buttonStyle(.plain)
    .focused($focusedSection, equals: item)
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .strokeBorder(
          color(SettingsPalette.oxford),
          lineWidth: focusedSection == item ? 2 : 0
        )
    )
    .accessibilityAddTraits(selected ? .isSelected : [])
    .accessibilityRemoveTraits(selected ? [] : .isSelected)
    .onHover { hovering in
      if hovering {
        hoveredSection = item
      } else if hoveredSection == item {
        hoveredSection = nil
      }
    }
  }

  private func sidebarFill(selected: Bool, hovered: Bool) -> Color {
    if selected { return color(SettingsPalette.surface3) }
    if hovered { return color(SettingsPalette.surface2) }
    return Color.clear
  }

  private var panel: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let lastError = model.lastError {
        errorBanner(lastError)
          .padding(.bottom, 16)
      }
      Text(section.copy.title)
        .font(.system(size: 26, weight: .bold, design: .serif))
        .foregroundStyle(color(SettingsPalette.ink))
      Text(section.copy.subtitle)
        .font(.system(size: 13))
        .foregroundStyle(color(SettingsPalette.inkMuted))
        .padding(.top, 4)
      ScrollView {
        sectionContent
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 4)
          .padding(.bottom, 8)
      }
      .padding(.top, 20)
    }
    .padding(.horizontal, 28)
    .padding(.top, 40)
    .padding(.bottom, 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(color(SettingsPalette.paper))
  }

  @ViewBuilder
  private var sectionContent: some View {
    switch section {
    case .mode:
      modeGrid
    case .exits:
      exitSettings
    case .general:
      generalSettings
    }
  }

  private var modeGrid: some View {
    LazyVGrid(
      columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
      spacing: 16
    ) {
      ForEach(KioskPlayModeCatalog.available, id: \.self) { mode in
        modeCard(mode)
      }
    }
    .padding(3)
  }

  private func modeCard(_ mode: KioskPlayModeID) -> some View {
    let selected = model.configuration.mode == mode
    let name = KioskPlayModeCatalog.displayName(mode)
    return Button {
      model.apply(.mode(mode))
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        PlayModeRegistry.preview(mode)
        Text(name)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(color(SettingsPalette.ink))
        Text(KioskPlayModeCatalog.tagline(mode))
          .font(.system(size: 12))
          .foregroundStyle(color(SettingsPalette.inkMuted))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(color(SettingsPalette.paperRaised))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(
            color(selected ? SettingsPalette.claret : SettingsPalette.rule),
            lineWidth: selected ? 3 : 1
          )
      )
      .overlay(alignment: .topTrailing) {
        if selected {
          Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color(SettingsPalette.paper))
            .frame(width: 20, height: 20)
            .background(Circle().fill(color(SettingsPalette.claret)))
            .padding(10)
            .accessibilityHidden(true)
        }
      }
    }
    .buttonStyle(.plain)
    .focused($focusedMode, equals: mode)
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(
          color(SettingsPalette.oxford),
          lineWidth: focusedMode == mode ? 2 : 0
        )
        .padding(1)
    )
    .accessibilityLabel(name)
    .accessibilityAddTraits(selected ? .isSelected : [])
    .accessibilityRemoveTraits(selected ? [] : .isSelected)
  }

  private var exitSettings: some View {
    VStack(alignment: .leading, spacing: 22) {
      parentExits
      timerSettings
    }
  }

  private var parentExits: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Sorties parent")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(color(SettingsPalette.ink))
      ForEach(manualExitCopies) { copy in
        manualExitToggle(copy)
      }
    }
  }

  private func manualExitToggle(_ copy: ManualExitCopy) -> some View {
    let isLast = isLastEnabledManualExit(copy.method)
    let help = isLast ? keepOneManualExitHelp : copy.help
    return VStack(alignment: .leading, spacing: 4) {
      Toggle(isOn: manualExitEnabled(copy.method)) {
        Text(copy.label)
          .foregroundStyle(color(SettingsPalette.ink))
      }
      .toggleStyle(.switch)
      .tint(color(SettingsPalette.claret))
      .disabled(isLast)
      .help(help)
      Text(help)
        .font(.system(size: 12))
        .foregroundStyle(color(SettingsPalette.inkMuted))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func manualExitEnabled(_ method: AdultExitMethod) -> Binding<Bool> {
    Binding(
      get: { model.configuration.exits.enabledMethods.contains(method) },
      set: { model.apply(.exitMethod(method, enabled: $0)) }
    )
  }

  private func isLastEnabledManualExit(_ method: AdultExitMethod) -> Bool {
    let enabled = model.configuration.exits.enabledMethods
    return enabled.count == 1 && enabled.contains(method)
  }

  private var timerSettings: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Minuteur")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(color(SettingsPalette.ink))
      HStack(spacing: 8) {
        Text("Fin de session après")
          .foregroundStyle(color(SettingsPalette.ink))
        TextField("minutes", text: $timeLimitDraft)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 64)
          .foregroundStyle(color(SettingsPalette.ink))
          .focused($timeLimitFieldFocused)
          .onSubmit(commitTimeLimitDraft)
          .onChange(of: timeLimitDraft) { draft in
            acceptTimeLimitDraft(draft, reportIncomplete: false)
          }
          .accessibilityLabel("Fin de session après, en minutes")
        Text("minutes")
          .foregroundStyle(color(SettingsPalette.ink))
        Stepper(
          "",
          value: timeLimitStepper,
          in: AdultExitSettings.timeLimitRange,
          step: 5
        )
        .labelsHidden()
        .accessibilityLabel("Durée de la session")
      }
      .onAppear(perform: seedTimeLimitDraft)
      .onChange(of: timeLimitFieldFocused) { focused in
        if !focused {
          commitTimeLimitDraft()
        }
      }
      if let timeLimitRejection {
        Text(timeLimitRejection)
          .font(.system(size: 12))
          .foregroundStyle(color(SettingsPalette.crimson))
          .fixedSize(horizontal: false, vertical: true)
      }
      Text(timeLimitHelp)
        .font(.system(size: 12))
        .foregroundStyle(color(SettingsPalette.inkMuted))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var timeLimitStepper: Binding<Int> {
    Binding(
      get: { model.configuration.exits.timeLimitMinutes },
      set: { minutes in
        timeLimitDraft = String(minutes)
        timeLimitRejection = nil
        model.apply(.timeLimitMinutes(minutes))
      }
    )
  }

  private func seedTimeLimitDraft() {
    guard timeLimitDraft.isEmpty, timeLimitRejection == nil else { return }
    timeLimitDraft = String(model.configuration.exits.timeLimitMinutes)
  }

  private func commitTimeLimitDraft() {
    acceptTimeLimitDraft(timeLimitDraft, reportIncomplete: true)
  }

  /// Une durée lisible et dans les bornes est enregistrée tout de suite.
  /// Un texte incomplet ne s’affiche en erreur qu’au moment de valider.
  private func acceptTimeLimitDraft(_ draft: String, reportIncomplete: Bool) {
    let trimmed = draft.trimmingCharacters(in: .whitespaces)
    guard let minutes = Int(trimmed) else {
      if reportIncomplete {
        timeLimitRejection = timeLimitRejectionMessage
      }
      return
    }
    guard AdultExitSettings.timeLimitRange.contains(minutes) else {
      timeLimitRejection = timeLimitRejectionMessage
      return
    }
    timeLimitRejection = nil
    guard minutes != model.configuration.exits.timeLimitMinutes else { return }
    model.apply(.timeLimitMinutes(minutes))
  }

  private var generalSettings: some View {
    VStack(alignment: .leading, spacing: 6) {
      Toggle(isOn: launchAtLogin) {
        Text("Démarrage automatique")
          .foregroundStyle(color(SettingsPalette.ink))
      }
      .toggleStyle(.switch)
      .tint(color(SettingsPalette.claret))
      .help(launchAtLoginHelp)
      Text(launchAtLoginHelp)
        .font(.system(size: 12))
        .foregroundStyle(color(SettingsPalette.inkMuted))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var launchAtLogin: Binding<Bool> {
    Binding(
      get: { model.configuration.launchAtLogin },
      set: { model.apply(.launchAtLogin($0)) }
    )
  }

  private func errorBanner(_ message: String) -> some View {
    Text(message)
      .font(.system(size: 13))
      .foregroundStyle(color(SettingsPalette.ink))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(color(SettingsPalette.crimsonWash))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .strokeBorder(color(SettingsPalette.crimson), lineWidth: 1)
      )
  }

  private func color(_ swatch: SettingsPalette.Swatch) -> Color {
    swatch.resolve(colorScheme)
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
    let hosting = NSHostingView(rootView: SettingsView(model: model))
    hosting.sizingOptions = []
    window.contentView = hosting
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
      contentRect: NSRect(
        x: 0,
        y: 0,
        width: SettingsWindowMetrics.width,
        height: SettingsWindowMetrics.height
      ),
      styleMask: [.titled, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "Réglages"
    window.identifier = NSUserInterfaceItemIdentifier("fr.camille.babywork.settings")
    window.isReleasedWhenClosed = false
    window.titlebarAppearsTransparent = true
    window.titlebarSeparatorStyle = .none
    window.backgroundColor = SettingsPalette.paper.nsColor
    window.delegate = self
    window.center()
    self.window = window
    return window
  }
}
