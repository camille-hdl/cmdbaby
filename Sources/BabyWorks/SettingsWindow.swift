import AppKit
import BabyWorkDiagnosticsKit
import OSLog
import ServiceManagement
import SwiftUI

private let settingsLogger = Logger(subsystem: "fr.camille.babywork", category: "Settings")

@MainActor
final class SettingsModel: ObservableObject {
  private let settings: BabyWorksSettings
  private let languageSettings: AppLanguageSettings
  private let languageAtLaunch: AppLanguagePreference
  @Published private(set) var configuration: BabyWorksConfiguration
  @Published private(set) var lastError: String?
  @Published private(set) var language: AppLanguagePreference

  /// La langue enregistrée n’est pas celle avec laquelle ce process a démarré.
  var languageNeedsRelaunch: Bool {
    language != languageAtLaunch
  }

  init(
    settings: BabyWorksSettings,
    languageSettings: AppLanguageSettings,
    languageAtLaunch: AppLanguagePreference
  ) {
    self.settings = settings
    self.languageSettings = languageSettings
    self.languageAtLaunch = languageAtLaunch
    self.configuration = settings.current()
    self.language = languageSettings.current()
  }

  func applyLanguage(_ preference: AppLanguagePreference) {
    languageSettings.apply(preference)
    language = languageSettings.current()
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
      case .passphrase:
        settingsLogger.error(
          "Impossible d’enregistrer la phrase de sortie : \(error.localizedDescription, privacy: .public)"
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
  /// Décollage commun : bords de la fenêtre, et intervalle entre barre et panneau.
  static let inset: CGFloat = 8
  /// Rayon commun de la barre, des groupes et des cartes.
  static let cornerRadius: CGFloat = 14
  /// Filet au repos, commun aux groupes et aux cartes.
  static let ruleOpacity = 0.45

  static let sidebarEntryHeight: CGFloat = 28
  static let sidebarEntryCornerRadius: CGFloat = 6
  static let sidebarEntrySpacing: CGFloat = 2
  static let sidebarEntryIconSize: CGFloat = 13
  static let sidebarEntryIconWidth: CGFloat = 18
  static let sidebarEntryFontSize: CGFloat = 13
  static let appTitleSize: CGFloat = 18
  static let sectionTitleSize: CGFloat = 22
  /// Depuis le haut de la barre, déjà décollée : le titre passe sous les feux.
  static let sidebarTitlebarClearance: CGFloat = 16
  static let panelTopPadding: CGFloat = 12
  static let headerToContentSpacing: CGFloat = 12
}

private struct SettingsSectionCopy {
  var title: String
  var subtitle: String
  var symbolName: String
}

enum SettingsSection: CaseIterable, Identifiable {
  case mode
  case exits
  case general
  case permissions
  case about

  var id: Self { self }

  fileprivate var copy: SettingsSectionCopy {
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
    case .permissions:
      SettingsSectionCopy(
        title: L10n.current("settings.permissions.title"),
        subtitle: L10n.current("settings.permissions.subtitle"),
        symbolName: "lock.shield"
      )
    case .about:
      SettingsSectionCopy(
        title: L10n.current("settings.about.title"),
        subtitle: L10n.current("settings.about.subtitle"),
        symbolName: "info.circle"
      )
    }
  }

  /// Section voisine dans l’ordre de la barre. Les extrémités ne bouclent pas.
  fileprivate func neighbor(moving direction: MoveCommandDirection) -> SettingsSection? {
    let delta: Int
    switch direction {
    case .up:
      delta = -1
    case .down:
      delta = 1
    case .left, .right:
      return nil
    @unknown default:
      return nil
    }
    let items = Array(Self.allCases)
    guard let index = items.firstIndex(of: self) else { return nil }
    let next = index + delta
    guard items.indices.contains(next) else { return nil }
    return items[next]
  }
}

private enum SettingsFormMetrics {
  static let rowHorizontalPadding: CGFloat = 12
  static let rowVerticalPadding: CGFloat = 10
  static let passphraseFieldWidth: CGFloat = 160
  static let timeLimitFieldWidth: CGFloat = 56
  static let scrollTrailingMargin: CGFloat = 16
  static let controlGap: CGFloat = 12
}

private func settingsColor(_ swatch: SettingsPalette.Swatch, _ scheme: ColorScheme) -> Color {
  swatch.resolve(scheme)
}

/// Groupe arrondi : titre facultatif, fond `paperRaised`, filet `rule`.
private struct SettingsGroup<Content: View>: View {
  var title: String?
  var content: Content
  @Environment(\.colorScheme) private var colorScheme

  init(title: String? = nil, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let title {
        Text(title)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(settingsColor(SettingsPalette.ink2, colorScheme))
      }
      VStack(spacing: 0) {
        content
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: SettingsWindowMetrics.cornerRadius, style: .continuous)
          .fill(settingsColor(SettingsPalette.paperRaised, colorScheme))
      }
      .overlay {
        RoundedRectangle(cornerRadius: SettingsWindowMetrics.cornerRadius, style: .continuous)
          .strokeBorder(
            settingsColor(SettingsPalette.rule, colorScheme)
              .opacity(SettingsWindowMetrics.ruleOpacity),
            lineWidth: 1
          )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Une ligne : libellé (et aide, rejet) à gauche, contrôle en bout de ligne.
private struct SettingsRow<Label: View, Control: View>: View {
  var label: Label
  var help: String?
  var rejection: String?
  var control: Control
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.isEnabled) private var isEnabled

  init(
    help: String? = nil,
    rejection: String? = nil,
    @ViewBuilder label: () -> Label,
    @ViewBuilder control: () -> Control
  ) {
    self.help = help
    self.rejection = rejection
    self.label = label()
    self.control = control()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        label
        if let help {
          Text(help)
            .font(.system(size: 12))
            .foregroundStyle(settingsColor(SettingsPalette.inkMuted, colorScheme))
            .fixedSize(horizontal: false, vertical: true)
        }
        if let rejection {
          Text(rejection)
            .font(.system(size: 12))
            .foregroundStyle(settingsColor(SettingsPalette.crimson, colorScheme))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      Spacer(minLength: SettingsFormMetrics.controlGap)
      control
    }
    .padding(.horizontal, SettingsFormMetrics.rowHorizontalPadding)
    .padding(.vertical, SettingsFormMetrics.rowVerticalPadding)
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isEnabled ? 1 : 0.45)
  }
}

private extension SettingsRow where Label == SettingsPlainLabel {
  init(
    label: String,
    help: String? = nil,
    rejection: String? = nil,
    @ViewBuilder control: () -> Control
  ) {
    self.init(help: help, rejection: rejection) {
      SettingsPlainLabel(text: label)
    } control: {
      control()
    }
  }
}

private extension SettingsRow where Control == EmptyView {
  init(
    help: String? = nil,
    rejection: String? = nil,
    @ViewBuilder label: () -> Label
  ) {
    self.init(help: help, rejection: rejection, label: label) {
      EmptyView()
    }
  }
}

private struct SettingsPlainLabel: View {
  var text: String
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Text(text)
      .font(.system(size: 13))
      .foregroundStyle(settingsColor(SettingsPalette.ink, colorScheme))
  }
}

/// Séparateur de ligne, calé sur le libellé plutôt que sur le bord du groupe.
private struct SettingsGroupDivider: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Divider()
      .overlay(settingsColor(SettingsPalette.rule, colorScheme))
      .padding(.leading, SettingsFormMetrics.rowHorizontalPadding)
  }
}

private let keepOneManualExitHelp = "Gardez au moins une sortie active."

private let passphraseHelp =
  "3 à 12 lettres, à taper en moins de 5 secondes puis Entrée."

private let timeLimitHelp =
  "Le contour du carré de secours se remplit pendant la session ; la session s’arrête quand il est complet."

private let timeLimitRejectionMessage =
  "Indique une durée entre \(AdultExitSettings.timeLimitRange.lowerBound) et \(AdultExitSettings.timeLimitRange.upperBound) minutes."

private let launchAtLoginHelp =
  "Ouvre BabyWorks dans la barre de menus au login, sans lancer de session."

struct SettingsView: View {
  @ObservedObject var model: SettingsModel
  @ObservedObject var session: DiagnosticsSessionModel
  @ObservedObject var presence: SettingsWindowPresence
  let onLaunch: () -> Void
  let onRelaunch: () -> Void
  @Environment(\.colorScheme) private var colorScheme
  @State private var section: SettingsSection
  @State private var hoveredSection: SettingsSection?
  /// Vrai seulement après Tab, une flèche ou un clic : à l’ouverture le système
  /// focalise une entrée sans que personne ait rien demandé.
  @State private var sidebarFocusEngaged = false
  /// Le prochain gain de focus de la barre compte comme une entrée au clavier.
  @State private var sidebarEntryPending = false
  @FocusState private var sidebarFocused: Bool
  @FocusState private var focusedMode: KioskPlayModeID?
  @FocusState private var focusedExit: AdultExitMethod?
  @FocusState private var launchAtLoginFocused: Bool
  @FocusState private var languageFocused: Bool
  @FocusState private var timeLimitFieldFocused: Bool
  @FocusState private var passphraseFieldFocused: Bool
  @FocusState private var focusedAboutLink: URL?
  @FocusState private var focusedPermissionAction: SetupAction?
  @State private var timeLimitDraft = ""
  @State private var timeLimitRejection: String?
  @State private var passphraseDraft = ""
  @State private var passphraseRejection: String?
  @State private var keyboardLayoutName: String?
  @State private var keyboardLayoutLetters: [UInt16: Set<Character>]
  @StateObject private var permissions: PermissionsMonitor

  init(
    model: SettingsModel,
    loginItem: any LoginItemRegistration,
    session: DiagnosticsSessionModel,
    presence: SettingsWindowPresence,
    initialSection: SettingsSection,
    onLaunch: @escaping () -> Void,
    onRelaunch: @escaping () -> Void
  ) {
    self.model = model
    self.session = session
    self.presence = presence
    self.onLaunch = onLaunch
    self.onRelaunch = onRelaunch
    _permissions = StateObject(
      wrappedValue: PermissionsMonitor(
        loginItem: loginItem,
        launchAtLoginRequested: { model.configuration.launchAtLogin },
        passphraseEnabled: {
          model.configuration.exits.enabledMethods.contains(.passphrase)
        },
        passphrase: { model.configuration.exits.passphrase }
      )
    )
    _section = State(initialValue: initialSection)
    _keyboardLayoutName = State(initialValue: KeyboardLayoutLetter.shared.layoutName)
    _keyboardLayoutLetters = State(initialValue: KeyboardLayoutLetter.shared.snapshot())
  }

  var body: some View {
    HStack(alignment: .top, spacing: SettingsWindowMetrics.inset) {
      sidebar
      panel
    }
    .padding(SettingsWindowMetrics.inset)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(color(SettingsPalette.paper))
    .ignoresSafeArea()
    .background {
      SidebarTabMonitor { handleSidebarTab(shift: $0) }
    }
    .tint(color(SettingsPalette.claret))
    .onChange(of: sidebarFocused) { isFocused in
      guard sidebarEntryPending else { return }
      sidebarEntryPending = false
      if isFocused {
        sidebarFocusEngaged = true
      }
    }
    .onAppear {
      permissions.setSectionVisible(section == .permissions)
      permissions.setWindowVisible(presence.isVisible)
    }
    .onChange(of: model.configuration) { _ in
      permissions.refresh()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: KeyboardLayoutLetter.didChangeNotification)
    ) { _ in
      permissions.refresh()
    }
    .onChange(of: section) { newSection in
      permissions.setSectionVisible(newSection == .permissions)
    }
    .onChange(of: presence.isVisible) { isVisible in
      permissions.setWindowVisible(isVisible)
    }
    .onDisappear {
      permissions.setSectionVisible(false)
      permissions.setWindowVisible(false)
    }
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("BabyWorks")
        .font(.system(size: SettingsWindowMetrics.appTitleSize, weight: .bold, design: .serif))
        .foregroundStyle(color(SettingsPalette.ink))
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
      VStack(alignment: .leading, spacing: SettingsWindowMetrics.sidebarEntrySpacing) {
        ForEach(SettingsSection.allCases) { item in
          sidebarRow(item)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 8)
    .padding(.top, SettingsWindowMetrics.sidebarTitlebarClearance)
    .padding(.bottom, 12)
    .frame(width: SettingsWindowMetrics.sidebarWidth, alignment: .topLeading)
    .frame(maxHeight: .infinity, alignment: .top)
    .background {
      RoundedRectangle(cornerRadius: SettingsWindowMetrics.cornerRadius, style: .continuous)
        .fill(color(SettingsPalette.surface1))
    }
    .focusable()
    .focused($sidebarFocused)
    .focusSection()
    .onMoveCommand(perform: moveSidebar)
    .settingsFocusRingHidden()
  }

  private func sidebarRow(_ item: SettingsSection) -> some View {
    let selected = section == item
    let showsFocus = sidebarShowsFocus && selected
    return Button {
      section = item
      sidebarFocused = true
      sidebarFocusEngaged = true
    } label: {
      HStack(spacing: 6) {
        Image(systemName: item.copy.symbolName)
          .font(.system(size: SettingsWindowMetrics.sidebarEntryIconSize, weight: .medium))
          .frame(width: SettingsWindowMetrics.sidebarEntryIconWidth)
        Text(item.copy.title)
          .font(.system(size: SettingsWindowMetrics.sidebarEntryFontSize, weight: selected ? .semibold : .regular))
        Spacer(minLength: 0)
        if item == .permissions, permissions.checklist.needsAttention {
          Circle()
            .fill(color(SettingsPalette.crimson))
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
        }
      }
      .foregroundStyle(sidebarForeground(selected: selected, showsFocus: showsFocus))
      .padding(.horizontal, 8)
      .frame(height: SettingsWindowMetrics.sidebarEntryHeight)
      .background(
        RoundedRectangle(cornerRadius: SettingsWindowMetrics.sidebarEntryCornerRadius, style: .continuous)
          .fill(
            sidebarFill(
              selected: selected,
              showsFocus: showsFocus,
              hovered: hoveredSection == item
            )
          )
      )
    }
    .buttonStyle(.plain)
    .focusable(false)
    .settingsFocusRingHidden()
    .modifier(SidebarAttentionLabel(label: sidebarAttentionLabel(item)))
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

  /// « Permissions, à corriger » seulement quand la liste demande une action.
  private func sidebarAttentionLabel(_ item: SettingsSection) -> String? {
    guard item == .permissions, permissions.checklist.needsAttention else { return nil }
    return L10n.current("settings.permissions.sidebar.attention")
  }

  /// La couleur `claret` remplace l’anneau : elle ne s’allume que si la barre
  /// a le focus et que l’utilisateur est entré dedans.
  private var sidebarShowsFocus: Bool {
    sidebarFocusEngaged && sidebarFocused
  }

  private func moveSidebar(_ direction: MoveCommandDirection) {
    switch direction {
    case .up, .down:
      sidebarFocusEngaged = true
      guard let next = section.neighbor(moving: direction) else { return }
      section = next
    case .left, .right:
      break
    @unknown default:
      break
    }
  }

  /// `true` si l’événement Tab est absorbé.
  /// Le premier Tab révèle la sélection. Le suivant quitte la barre vers le panneau.
  private func handleSidebarTab(shift: Bool) -> Bool {
    if sidebarFocused && !sidebarFocusEngaged {
      sidebarFocusEngaged = true
      return true
    }
    if sidebarFocused && sidebarFocusEngaged {
      if shift {
        return false
      }
      sidebarFocused = false
      focusFirstPanelControl()
      return true
    }
    if !sidebarFocused && !sidebarFocusEngaged {
      sidebarEntryPending = true
    }
    return false
  }

  /// Tab sort de la barre vers le premier contrôle du panneau visible.
  private func focusFirstPanelControl() {
    switch section {
    case .mode:
      focusedMode = KioskPlayModeCatalog.available.first
    case .exits:
      focusedExit = .passphrase
    case .general:
      languageFocused = true
    case .permissions:
      focusedPermissionAction = permissions.checklist.checks.first?.actions.first
    case .about:
      focusedAboutLink = Credits.authorURL
    }
  }

  private func sidebarFill(selected: Bool, showsFocus: Bool, hovered: Bool) -> Color {
    if selected && showsFocus { return color(SettingsPalette.claret) }
    if selected { return color(SettingsPalette.surface3) }
    if hovered { return color(SettingsPalette.surface2) }
    return Color.clear
  }

  private func sidebarForeground(selected: Bool, showsFocus: Bool) -> Color {
    if selected && showsFocus { return color(SettingsPalette.paper) }
    if selected { return color(SettingsPalette.ink) }
    return color(SettingsPalette.ink2)
  }

  private var panel: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let lastError = model.lastError {
        errorBanner(lastError)
          .padding(.bottom, 16)
      }
      Text(section.copy.title)
        .font(.system(size: SettingsWindowMetrics.sectionTitleSize, weight: .bold, design: .serif))
        .foregroundStyle(color(SettingsPalette.ink))
      Text(section.copy.subtitle)
        .font(.system(size: 13))
        .foregroundStyle(color(SettingsPalette.inkMuted))
        .padding(.top, 2)
      ScrollView {
        sectionContent
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 2)
          .padding(.bottom, 8)
          .padding(.trailing, SettingsFormMetrics.scrollTrailingMargin)
      }
      .padding(.top, SettingsWindowMetrics.headerToContentSpacing)
    }
    .padding(.horizontal, 28)
    .padding(.top, SettingsWindowMetrics.panelTopPadding)
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
    case .permissions:
      permissionsSettings
    case .about:
      aboutSettings
    }
  }

  private var modeGrid: some View {
    LazyVGrid(
      columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
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
    let focused = focusedMode == mode
    let stroke = modeCardStroke(selected: selected, focused: focused)
    let name = KioskPlayModeCatalog.displayName(mode)
    return VStack(alignment: .leading, spacing: 8) {
      Button {
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
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .focused($focusedMode, equals: mode)
      .settingsFocusRingHidden()
      .accessibilityLabel(name)
      .accessibilityAddTraits(selected ? .isSelected : [])
      .accessibilityRemoveTraits(selected ? [] : .isSelected)

      Button {
        model.apply(.mode(mode))
        onLaunch()
      } label: {
        Text(L10n.current("settings.mode.launch"))
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.small)
      .tint(color(SettingsPalette.claret))
      .accessibilityLabel(L10n.current("settings.mode.launch.accessibility", name))
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: SettingsWindowMetrics.cornerRadius, style: .continuous)
        .fill(color(SettingsPalette.paperRaised))
    )
    .overlay(
      RoundedRectangle(cornerRadius: SettingsWindowMetrics.cornerRadius, style: .continuous)
        .strokeBorder(
          color(stroke.swatch).opacity(stroke.opacity),
          lineWidth: stroke.width
        )
        .allowsHitTesting(false)
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
          .allowsHitTesting(false)
      }
    }
  }

  /// Carte sélectionnée : bord `claret`. Carte focalisée : `oxford` 2 pt.
  /// Au repos, le filet est celui des groupes. Pas d’anneau posé par-dessus.
  private func modeCardStroke(selected: Bool, focused: Bool) -> (swatch: SettingsPalette.Swatch, width: CGFloat, opacity: Double) {
    if selected { return (SettingsPalette.claret, 3, 1) }
    if focused { return (SettingsPalette.oxford, 2, 1) }
    return (SettingsPalette.rule, 1, SettingsWindowMetrics.ruleOpacity)
  }

  private var exitSettings: some View {
    VStack(alignment: .leading, spacing: 22) {
      parentExits
      timerSettings
    }
  }

  private var parentExits: some View {
    SettingsGroup(title: "Sorties parent") {
      exitToggleRow(method: .passphrase, label: "Phrase + Entrée", help: nil)
      SettingsGroupDivider()
      passphraseRow
      if passphraseExitEnabled {
        SettingsGroupDivider()
        keyboardLayoutRow
      }
      SettingsGroupDivider()
      exitToggleRow(method: .shiftEscape, label: "Maj-Échap", help: "Majuscule + Échap")
      SettingsGroupDivider()
      exitToggleRow(
        method: .failsafeClick,
        label: "Clics de secours",
        help: "5 clics rapides sur le carré en bas à droite"
      )
    }
    .onAppear(perform: refreshKeyboardLayout)
    .onReceive(
      NotificationCenter.default.publisher(for: KeyboardLayoutLetter.didChangeNotification)
    ) { _ in
      refreshKeyboardLayout()
    }
  }

  private var passphraseExitEnabled: Bool {
    model.configuration.exits.enabledMethods.contains(.passphrase)
  }

  private var keyboardLayoutRow: some View {
    let typability = PassphraseTypability.check(
      model.configuration.exits.passphrase,
      layoutLetters: keyboardLayoutLetters
    )
    let missing = typability.missingLetters.map(String.init).joined(separator: " ")
    return SettingsRow(
      label: L10n.current("settings.exits.layout.label"),
      help: typability.isTypable ? L10n.current("settings.exits.layout.ok") : nil,
      rejection: typability.isTypable
        ? nil
        : L10n.current("settings.exits.layout.missing", missing)
    ) {
      Text(keyboardLayoutName ?? "")
        .font(.system(size: 13))
        .foregroundStyle(color(SettingsPalette.ink))
    }
  }

  private func refreshKeyboardLayout() {
    keyboardLayoutName = KeyboardLayoutLetter.shared.layoutName
    keyboardLayoutLetters = KeyboardLayoutLetter.shared.snapshot()
  }

  private func exitToggleRow(method: AdultExitMethod, label: String, help: String?) -> some View {
    let isLast = isLastEnabledManualExit(method)
    return SettingsRow(label: label, help: isLast ? keepOneManualExitHelp : help) {
      settingsSwitch(label, isOn: manualExitEnabled(method))
        .focused($focusedExit, equals: method)
        .disabled(isLast)
    }
  }

  private var passphraseRow: some View {
    let enabled = model.configuration.exits.enabledMethods.contains(.passphrase)
    return SettingsRow(
      label: "Phrase de sortie",
      help: passphraseHelp,
      rejection: passphraseRejection
    ) {
      TextField("Phrase de sortie", text: $passphraseDraft)
        .textFieldStyle(.roundedBorder)
        .controlSize(.small)
        .frame(width: SettingsFormMetrics.passphraseFieldWidth)
        .foregroundStyle(color(SettingsPalette.ink))
        .focused($passphraseFieldFocused)
        .onSubmit(commitPassphraseDraft)
        .accessibilityLabel("Phrase de sortie")
    }
    .disabled(!enabled)
    .onAppear(perform: seedPassphraseDraft)
    .onChange(of: passphraseFieldFocused) { focused in
      if !focused {
        commitPassphraseDraft()
      }
    }
  }

  private func settingsSwitch(_ label: String, isOn: Binding<Bool>) -> some View {
    Toggle(isOn: isOn) {
      Text(label)
    }
    .labelsHidden()
    .toggleStyle(.switch)
    .controlSize(.small)
    .tint(color(SettingsPalette.claret))
    .accessibilityLabel(label)
  }

  private func seedPassphraseDraft() {
    guard passphraseDraft.isEmpty, passphraseRejection == nil else { return }
    passphraseDraft = model.configuration.exits.passphrase.value
  }

  private func commitPassphraseDraft() {
    do {
      let parsed = try ExitPassphrase.parse(passphraseDraft)
      passphraseRejection = nil
      passphraseDraft = parsed.value
      guard parsed != model.configuration.exits.passphrase else { return }
      model.apply(.passphrase(parsed.value))
    } catch let error as SettingsError {
      passphraseRejection = error.errorDescription
    } catch {
      passphraseRejection = SettingsError.passphraseInvalidCharacters.errorDescription
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
    SettingsGroup(title: "Minuteur") {
      SettingsRow(
        label: "Fin de session après",
        help: timeLimitHelp,
        rejection: timeLimitRejection
      ) {
        HStack(spacing: 6) {
          TextField("minutes", text: $timeLimitDraft)
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)
            .multilineTextAlignment(.trailing)
            .frame(width: SettingsFormMetrics.timeLimitFieldWidth)
            .foregroundStyle(color(SettingsPalette.ink))
            .focused($timeLimitFieldFocused)
            .onSubmit(commitTimeLimitDraft)
            .onChange(of: timeLimitDraft) { draft in
              acceptTimeLimitDraft(draft, reportIncomplete: false)
            }
            .accessibilityLabel("Fin de session après, en minutes")
          Text("min")
            .font(.system(size: 13))
            .foregroundStyle(color(SettingsPalette.ink))
          Stepper(
            "",
            value: timeLimitStepper,
            in: AdultExitSettings.timeLimitRange,
            step: 1
          )
          .controlSize(.small)
          .labelsHidden()
          .accessibilityLabel("Durée de la session")
        }
        .onAppear(perform: seedTimeLimitDraft)
        .onChange(of: timeLimitFieldFocused) { focused in
          if !focused {
            commitTimeLimitDraft()
          }
        }
      }
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
    SettingsGroup {
      languageRow
      SettingsGroupDivider()
      SettingsRow(label: "Démarrage automatique", help: launchAtLoginHelp) {
        settingsSwitch("Démarrage automatique", isOn: launchAtLogin)
          .focused($launchAtLoginFocused)
      }
    }
  }

  private var languageRow: some View {
    let label = L10n.current("settings.general.language.label")
    return SettingsRow(
      label: label,
      help: model.languageNeedsRelaunch
        ? L10n.current("settings.general.language.relaunch.help") : nil
    ) {
      HStack(spacing: 8) {
        Picker(label, selection: languagePreference) {
          ForEach(AppLanguagePreference.allCases, id: \.self) { preference in
            Text(languageMenuTitle(preference)).tag(preference)
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .controlSize(.small)
        .fixedSize()
        .focused($languageFocused)
        .accessibilityLabel(label)
        if model.languageNeedsRelaunch {
          Button(L10n.current("settings.general.language.relaunch.action")) {
            onRelaunch()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      }
      .disabled(session.isTerminationBlocked)
    }
  }

  private var languagePreference: Binding<AppLanguagePreference> {
    Binding(
      get: { model.language },
      set: { model.applyLanguage($0) }
    )
  }

  /// *English* et *Français* restent dans leur langue ; *Système* suit la table.
  private func languageMenuTitle(_ preference: AppLanguagePreference) -> String {
    switch preference {
    case .system:
      L10n.current("settings.general.language.system")
    case .english:
      L10n.current("settings.general.language.english")
    case .french:
      L10n.current("settings.general.language.french")
    }
  }

  private var permissionsSettings: some View {
    VStack(alignment: .leading, spacing: 22) {
      ForEach(permissions.checklist.checks, id: \.id) { check in
        permissionsGroup(check)
      }
    }
  }

  private func permissionsGroup(_ check: SetupCheck) -> some View {
    let symbol = permissionsSymbol(check.state)
    return SettingsGroup {
      SettingsRow(help: check.localizedDetail(in: L10n.current)) {
        HStack(spacing: 8) {
          Image(systemName: symbol.name)
            .font(.system(size: 16))
            .foregroundStyle(color(symbol.swatch))
            .accessibilityHidden(true)
          Text(L10n.current(check.titleKey))
            .font(.system(size: 13))
            .foregroundStyle(color(SettingsPalette.ink))
        }
      } control: {
        permissionsActions(check)
      }
    }
  }

  @ViewBuilder
  private func permissionsActions(_ check: SetupCheck) -> some View {
    if !check.actions.isEmpty {
      VStack(alignment: .trailing, spacing: 6) {
        ForEach(check.actions, id: \.self) { action in
          Button(permissionsActionTitle(action)) {
            performPermissionsAction(action)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .focused($focusedPermissionAction, equals: action)
        }
      }
      .fixedSize(horizontal: true, vertical: false)
    }
  }

  private func permissionsSymbol(
    _ state: SetupCheckState
  ) -> (name: String, swatch: SettingsPalette.Swatch) {
    switch state {
    case .ok:
      ("checkmark.circle.fill", SettingsPalette.jade)
    case .attention:
      ("exclamationmark.triangle.fill", SettingsPalette.crimson)
    }
  }

  private func permissionsActionTitle(_ action: SetupAction) -> String {
    switch action {
    case .requestAccessibility:
      L10n.current("settings.permissions.action.request")
    case .openAccessibilitySettings, .openLoginItemsSettings:
      L10n.current("settings.permissions.action.openSettings")
    case .revealInFinder:
      L10n.current("settings.permissions.action.revealInFinder")
    case .showExitsSection:
      L10n.current("settings.permissions.action.changePhrase")
    }
  }

  private func performPermissionsAction(_ action: SetupAction) {
    switch action {
    case .requestAccessibility:
      AccessibilitySettings.requestAccess()
    case .openAccessibilitySettings:
      AccessibilitySettings.openSystemSettings()
    case .revealInFinder:
      NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    case .openLoginItemsSettings:
      SMAppService.openSystemSettingsLoginItems()
    case .showExitsSection:
      section = .exits
    }
  }

  private var aboutSettings: some View {
    VStack(alignment: .leading, spacing: 22) {
      SettingsGroup {
        SettingsRow(label: installedAppName) {
          Text(installedAppVersion)
            .font(.system(size: 13))
            .foregroundStyle(color(SettingsPalette.ink))
        }
        SettingsGroupDivider()
        aboutAuthorRow
      }
      SettingsGroup(title: L10n.current("settings.about.assets")) {
        ForEach(Array(Credits.assets.enumerated()), id: \.element.url) { index, asset in
          VStack(spacing: 0) {
            if index > 0 {
              SettingsGroupDivider()
            }
            aboutAssetRow(asset)
          }
        }
      }
    }
  }

  private var aboutAuthorRow: some View {
    SettingsRow {
      HStack(spacing: 0) {
        Text(L10n.current("settings.about.madeBy") + " ")
          .font(.system(size: 13))
          .foregroundStyle(color(SettingsPalette.ink))
          .accessibilityHidden(true)
        Link(Credits.authorName, destination: Credits.authorURL)
          .font(.system(size: 13))
          .focused($focusedAboutLink, equals: Credits.authorURL)
          .accessibilityLabel(madeByLine)
      }
    }
  }

  private var madeByLine: String {
    "\(L10n.current("settings.about.madeBy")) \(Credits.authorName)"
  }

  private func aboutAssetRow(_ asset: CreditedAsset) -> some View {
    SettingsRow(help: L10n.current("settings.about.asset.credit", asset.author, asset.license)) {
      Link(asset.name, destination: asset.url)
        .font(.system(size: 13))
        .focused($focusedAboutLink, equals: asset.url)
    }
  }

  /// Nom affiché de l’app. Repli traduit hors bundle `.app`.
  private var installedAppName: String {
    InstalledAppLabel.name(
      displayName: bundleString("CFBundleDisplayName"),
      bundleName: bundleString("CFBundleName")
    ) ?? L10n.current("settings.about.name.fallback")
  }

  /// `CFBundleShortVersionString` (`CFBundleVersion`). Chaîne traduite si l’un des deux manque (`swift run`).
  private var installedAppVersion: String {
    InstalledAppLabel.version(
      shortVersion: bundleString("CFBundleShortVersionString"),
      build: bundleString("CFBundleVersion")
    ) ?? L10n.current("settings.about.version.missing")
  }

  private func bundleString(_ key: String) -> String? {
    Bundle.main.object(forInfoDictionaryKey: key) as? String
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
    settingsColor(swatch, colorScheme)
  }
}

/// Remplace le libellé vocal de l’entrée Permissions quand il y a quelque chose à corriger.
private struct SidebarAttentionLabel: ViewModifier {
  var label: String?

  func body(content: Content) -> some View {
    if let label {
      content.accessibilityLabel(label)
    } else {
      content
    }
  }
}

private extension View {
  @ViewBuilder
  func settingsFocusRingHidden() -> some View {
    if #available(macOS 14, *) {
      focusEffectDisabled()
    } else {
      self
    }
  }
}

/// TCC et le Login Item ne notifient pas : relire les faits tant que Permissions est visible.
@MainActor
private final class PermissionsMonitor: ObservableObject {
  @Published private(set) var checklist: SetupChecklist
  private var timer: Timer?
  private var sectionVisible = false
  private var windowVisible = false
  private let loginItem: any LoginItemRegistration
  private let launchAtLoginRequested: @MainActor () -> Bool
  private let passphraseEnabled: @MainActor () -> Bool
  private let passphrase: @MainActor () -> ExitPassphrase

  init(
    loginItem: any LoginItemRegistration,
    launchAtLoginRequested: @escaping @MainActor () -> Bool,
    passphraseEnabled: @escaping @MainActor () -> Bool,
    passphrase: @escaping @MainActor () -> ExitPassphrase
  ) {
    self.loginItem = loginItem
    self.launchAtLoginRequested = launchAtLoginRequested
    self.passphraseEnabled = passphraseEnabled
    self.passphrase = passphrase
    checklist = Self.checklist(
      loginItem: loginItem,
      launchAtLoginRequested: launchAtLoginRequested(),
      passphraseEnabled: passphraseEnabled(),
      passphrase: passphrase()
    )
  }

  isolated deinit {
    timer?.invalidate()
  }

  func setSectionVisible(_ visible: Bool) {
    sectionVisible = visible
    updateWatch()
  }

  func setWindowVisible(_ visible: Bool) {
    windowVisible = visible
    updateWatch()
  }

  private func updateWatch() {
    let watch = sectionVisible && windowVisible
    if watch {
      guard timer == nil else { return }
      refresh()
      let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
        Task { @MainActor in
          self?.refresh()
        }
      }
      RunLoop.main.add(timer, forMode: .common)
      self.timer = timer
    } else {
      timer?.invalidate()
      timer = nil
    }
  }

  fileprivate func refresh() {
    let checklist = Self.checklist(
      loginItem: loginItem,
      launchAtLoginRequested: launchAtLoginRequested(),
      passphraseEnabled: passphraseEnabled(),
      passphrase: passphrase()
    )
    guard checklist != self.checklist else { return }
    self.checklist = checklist
  }

  private static func checklist(
    loginItem: any LoginItemRegistration,
    launchAtLoginRequested: Bool,
    passphraseEnabled: Bool,
    passphrase: ExitPassphrase
  ) -> SetupChecklist {
    SetupChecklist(
      facts: SetupFacts(
        accessibilityGranted: AccessibilitySettings.isProcessTrusted(),
        bundlePath: Bundle.main.bundlePath,
        homeDirectory: FileManager.default.homeDirectoryForCurrentUser.path,
        launchAtLoginRequested: launchAtLoginRequested,
        loginItemStatus: loginItem.status,
        passphraseEnabled: passphraseEnabled,
        passphraseTypability: PassphraseTypability.check(
          passphrase,
          layoutLetters: KeyboardLayoutLetter.shared.snapshot()
        ),
        layoutName: KeyboardLayoutLetter.shared.layoutName
      )
    )
  }
}

/// Vrai une fois que l’ouverture a réellement affiché la fenêtre, faux dès qu’elle se ferme.
@MainActor
final class SettingsWindowPresence: ObservableObject {
  @Published private(set) var isVisible = false

  func setVisible(_ isVisible: Bool) {
    guard isVisible != self.isVisible else { return }
    self.isVisible = isVisible
  }
}

/// Intercepte le premier Tab tant que la barre n’est pas engagée.
/// Le système a déjà posé le focus : ce Tab doit révéler la sélection, pas la quitter.
private struct SidebarTabMonitor: NSViewRepresentable {
  var onTab: (Bool) -> Bool

  func makeNSView(context: Context) -> MonitorView {
    MonitorView()
  }

  func updateNSView(_ nsView: MonitorView, context: Context) {
    nsView.onTab = onTab
  }

  static func dismantleNSView(_ nsView: MonitorView, coordinator: ()) {
    nsView.removeMonitor()
  }

  final class MonitorView: NSView {
    var onTab: (Bool) -> Bool = { _ in false }
    private var monitor: Any?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      if window == nil {
        removeMonitor()
        return
      }
      guard monitor == nil else { return }
      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self else { return event }
        guard event.window === self.window, self.isPlainTab(event) else { return event }
        let shift = event.modifierFlags.contains(.shift)
        return self.onTab(shift) ? nil : event
      }
    }

    func removeMonitor() {
      guard let monitor else { return }
      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }

    private func isPlainTab(_ event: NSEvent) -> Bool {
      event.keyCode == MacVirtualKeyCode.tab
        && event.modifierFlags.intersection([.command, .control, .option]).isEmpty
    }
  }
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
  private let store: BabyWorksConfigurationStore
  private let loginItem: any LoginItemRegistration
  private let languageSettings: AppLanguageSettings
  private let languageAtLaunch: AppLanguagePreference
  private let session: DiagnosticsSessionModel
  private let log: LifecycleLogRecorder
  private let onLaunch: () -> Void
  private let onRelaunch: () -> Void
  private var window: NSWindow?
  private let presence = SettingsWindowPresence()
  private var model: SettingsModel?
  private var showSequence: SettingsShowSequence?
  private var showGeneration = 0
  private var trackingMenu: NSMenu?
  private var waitingForMenuTracking = false
  private var menuTrackingProceed: (@MainActor () -> Void)?

  init(
    store: BabyWorksConfigurationStore = BabyWorksConfigurationStore(),
    loginItem: any LoginItemRegistration = SMAppServiceLoginItem(),
    languageSettings: AppLanguageSettings = AppLanguageSettings(store: UserDefaultsAppLanguageStore()),
    languageAtLaunch: AppLanguagePreference,
    session: DiagnosticsSessionModel,
    log: LifecycleLogRecorder = .shared,
    onRelaunch: @escaping () -> Void,
    onLaunch: @escaping () -> Void
  ) {
    self.store = store
    self.loginItem = loginItem
    self.languageSettings = languageSettings
    self.languageAtLaunch = languageAtLaunch
    self.session = session
    self.log = log
    self.onRelaunch = onRelaunch
    self.onLaunch = onLaunch
    super.init()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func show(
    fromStatusItemMenu: Bool = true,
    trackingMenu: NSMenu? = nil,
    section: SettingsSection = .mode
  ) {
    cancelPendingShow()
    log.emit(.settingsShowRequest)
    let model = SettingsModel(
      settings: BabyWorksSettings(store: store, loginItem: loginItem),
      languageSettings: languageSettings,
      languageAtLaunch: languageAtLaunch
    )
    self.model = model
    let window = existingOrMakeWindow()
    let hosting = NSHostingView(
      rootView: SettingsView(
        model: model,
        loginItem: loginItem,
        session: session,
        presence: presence,
        initialSection: section,
        onLaunch: onLaunch,
        onRelaunch: onRelaunch
      )
    )
    hosting.sizingOptions = []
    window.contentView = hosting
    self.trackingMenu = trackingMenu
    showSequence = SettingsShowSequence(fromStatusItemMenu: fromStatusItemMenu)
    continueShow()
  }

  func hide() {
    cancelPendingShow()
    presence.setVisible(false)
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
    presence.setVisible(visible)
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
    window.titleVisibility = .hidden
    window.titlebarSeparatorStyle = .none
    window.backgroundColor = SettingsPalette.paper.nsColor
    window.delegate = self
    window.center()
    self.window = window
    return window
  }
}
