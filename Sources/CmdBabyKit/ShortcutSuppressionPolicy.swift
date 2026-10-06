import Foundation

/// Masque de modificateurs pertinent pour classer les raccourcis système.
/// Indépendant de Core Graphics afin de rester testable sans API système.
public struct InputModifierMask: OptionSet, Sendable, Hashable {
  public let rawValue: UInt64

  public init(rawValue: UInt64) {
    self.rawValue = rawValue
  }

  public static let command = InputModifierMask(rawValue: 1 << 0)
  public static let option = InputModifierMask(rawValue: 1 << 1)
  public static let control = InputModifierMask(rawValue: 1 << 2)
  public static let shift = InputModifierMask(rawValue: 1 << 3)

  /// Modificateurs qui distinguent les raccourcis surveillés (Majuscule exclu).
  public static let distinguishing: InputModifierMask = [.command, .option, .control]
}

/// Raccourcis dont la suppression doit être démontrée en phase 0.
public enum MonitoredShortcut: String, CaseIterable, Sendable, Equatable, Hashable {
  case commandSpace
  case optionSpace
  case controlSpace
  case controlOptionSpace
  case commandTab
  case commandQ
  case commandH
  case commandM
  case optionCommandEscape
  case controlUp
  case controlDown
  case controlCommandQ
  /// Toute autre combinaison avec Commande ou Contrôle (Espaces, captures, VoiceOver, emojis…).
  case otherCommandOrControl
  case functionKey
  case fnGlobe
  /// Touches système hors clavier principal : média, luminosité, volume, Spotlight, Dictée…
  case auxiliaryKey

  public var displayName: String {
    switch self {
    case .commandSpace:
      "Commande-Espace"
    case .optionSpace:
      "Option-Espace"
    case .controlSpace:
      "Contrôle-Espace"
    case .controlOptionSpace:
      "Contrôle-Option-Espace"
    case .commandTab:
      "Commande-Tab"
    case .commandQ:
      "Commande-Q"
    case .commandH:
      "Commande-H"
    case .commandM:
      "Commande-M"
    case .optionCommandEscape:
      "Option-Commande-Échap"
    case .controlUp:
      "Contrôle-↑"
    case .controlDown:
      "Contrôle-↓"
    case .controlCommandQ:
      "Contrôle-Commande-Q"
    case .otherCommandOrControl:
      "Autre raccourci Commande ou Contrôle"
    case .functionKey:
      "Touche de fonction"
    case .fnGlobe:
      "Touche fn/Globe"
    case .auxiliaryKey:
      "Touche système"
    }
  }
}

public enum InputFilterDecision: Equatable, Sendable {
  case allow
  case suppress(MonitoredShortcut)
}

/// Codes virtuels macOS (HIToolbox) utilisés par le prototype.
public enum MacVirtualKeyCode {
  public static let ansiQ: UInt16 = 0x0C
  public static let ansiH: UInt16 = 0x04
  public static let ansiM: UInt16 = 0x2E
  public static let space: UInt16 = 0x31
  public static let tab: UInt16 = 0x30
  public static let escape: UInt16 = 0x35
  public static let upArrow: UInt16 = 0x7E
  public static let downArrow: UInt16 = 0x7D
  public static let function: UInt16 = 0x3F
  /// F1 à F20.
  public static let functionKeys: Set<UInt16> = [
    0x7A, 0x78, 0x63, 0x76, 0x60, 0x61, 0x62, 0x64, 0x65, 0x6D,
    0x67, 0x6F, 0x69, 0x6B, 0x71, 0x6A, 0x40, 0x4F, 0x50, 0x5A,
  ]
}

/// Décide si une frappe doit être absorbée pendant une session. Hors session, aucun tap n’est installé.
/// Par catégories : toute combinaison avec Commande ou Contrôle, les touches de fonction,
/// fn/Globe et les touches système. Les sorties adulte n’utilisent ni Commande ni Contrôle.
/// Le caractère n’est utilisé que pour nommer Q/H/M selon la disposition (AZERTY compris) ;
/// il n’est jamais journalisé.
public enum ShortcutSuppressionPolicy {
  /// Sous-type `NX_SUBTYPE_AUX_CONTROL_BUTTONS` des événements `NX_SYSDEFINED` (type 14).
  public static let auxiliaryKeySubtype = 8
  private struct Rule {
    let shortcut: MonitoredShortcut
    let keyCode: UInt16?
    let letter: Character?
    let modifiers: InputModifierMask
  }

  private static let rules: [Rule] = [
    Rule(shortcut: .commandSpace, keyCode: MacVirtualKeyCode.space, letter: nil, modifiers: [.command]),
    Rule(shortcut: .optionSpace, keyCode: MacVirtualKeyCode.space, letter: nil, modifiers: [.option]),
    Rule(shortcut: .controlSpace, keyCode: MacVirtualKeyCode.space, letter: nil, modifiers: [.control]),
    Rule(
      shortcut: .controlOptionSpace,
      keyCode: MacVirtualKeyCode.space,
      letter: nil,
      modifiers: [.control, .option]
    ),
    Rule(shortcut: .commandTab, keyCode: MacVirtualKeyCode.tab, letter: nil, modifiers: [.command]),
    Rule(shortcut: .commandQ, keyCode: MacVirtualKeyCode.ansiQ, letter: "q", modifiers: [.command]),
    Rule(shortcut: .commandH, keyCode: MacVirtualKeyCode.ansiH, letter: "h", modifiers: [.command]),
    Rule(shortcut: .commandM, keyCode: MacVirtualKeyCode.ansiM, letter: "m", modifiers: [.command]),
    Rule(
      shortcut: .optionCommandEscape,
      keyCode: MacVirtualKeyCode.escape,
      letter: nil,
      modifiers: [.option, .command]
    ),
    Rule(shortcut: .controlUp, keyCode: MacVirtualKeyCode.upArrow, letter: nil, modifiers: [.control]),
    Rule(shortcut: .controlDown, keyCode: MacVirtualKeyCode.downArrow, letter: nil, modifiers: [.control]),
    Rule(
      shortcut: .controlCommandQ,
      keyCode: MacVirtualKeyCode.ansiQ,
      letter: "q",
      modifiers: [.control, .command]
    ),
  ]

  public static func decision(
    keyCode: UInt16,
    modifiers: InputModifierMask,
    letter: Character? = nil
  ) -> InputFilterDecision {
    let distinguishing = modifiers.intersection(.distinguishing)
    let normalizedLetter = letter.flatMap { $0.lowercased().first }
    for rule in rules where rule.modifiers == distinguishing {
      if let expected = rule.letter, normalizedLetter == expected {
        return .suppress(rule.shortcut)
      }
      if let expectedKey = rule.keyCode, expectedKey == keyCode {
        return .suppress(rule.shortcut)
      }
    }
    if MacVirtualKeyCode.functionKeys.contains(keyCode) {
      return .suppress(.functionKey)
    }
    if !distinguishing.isDisjoint(with: [.command, .control]) {
      return .suppress(.otherCommandOrControl)
    }
    return .allow
  }

  /// `flagsChanged` : seule la touche fn/Globe (emojis, dictée, bureau) est absorbée.
  public static func flagsChangedDecision(keyCode: UInt16) -> InputFilterDecision {
    keyCode == MacVirtualKeyCode.function ? .suppress(.fnGlobe) : .allow
  }

  /// Événement `NX_SYSDEFINED` : seules les touches auxiliaires sont absorbées.
  public static func systemDefinedDecision(subtype: Int) -> InputFilterDecision {
    subtype == auxiliaryKeySubtype ? .suppress(.auxiliaryKey) : .allow
  }
}

/// État observable du filtre, sans donnée de frappe.
public enum InputFilterStatus: Equatable, Sendable {
  case inactive
  case starting
  case active
  case disabledByTimeout
  case disabledByUserInput
  case failed(String)

  public var displayName: String {
    switch self {
    case .inactive:
      "Inactif"
    case .starting:
      "Démarrage…"
    case .active:
      "Actif"
    case .disabledByTimeout:
      "Désactivé (délai)"
    case .disabledByUserInput:
      "Désactivé (intervention)"
    case .failed(let reason):
      "Échec — \(reason)"
    }
  }

  public var isRunning: Bool {
    switch self {
    case .active, .starting, .disabledByTimeout, .disabledByUserInput:
      true
    case .inactive, .failed:
      false
    }
  }
}
