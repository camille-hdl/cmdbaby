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
  case commandTab
  case commandQ
  case commandH
  case commandM
  case optionCommandEscape
  case controlUp
  case controlDown
  case controlCommandQ

  public var displayName: String {
    switch self {
    case .commandSpace:
      "Commande-Espace"
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
  public static let downArrow: UInt16 = 0x7F
}

/// Décide si une frappe doit être absorbée. Ne voit jamais le caractère saisi.
public enum ShortcutSuppressionPolicy {
  private struct Rule {
    let shortcut: MonitoredShortcut
    let keyCode: UInt16
    let modifiers: InputModifierMask
  }

  private static let rules: [Rule] = [
    Rule(shortcut: .commandSpace, keyCode: MacVirtualKeyCode.space, modifiers: [.command]),
    Rule(shortcut: .commandTab, keyCode: MacVirtualKeyCode.tab, modifiers: [.command]),
    Rule(shortcut: .commandQ, keyCode: MacVirtualKeyCode.ansiQ, modifiers: [.command]),
    Rule(shortcut: .commandH, keyCode: MacVirtualKeyCode.ansiH, modifiers: [.command]),
    Rule(shortcut: .commandM, keyCode: MacVirtualKeyCode.ansiM, modifiers: [.command]),
    Rule(
      shortcut: .optionCommandEscape,
      keyCode: MacVirtualKeyCode.escape,
      modifiers: [.option, .command]
    ),
    Rule(shortcut: .controlUp, keyCode: MacVirtualKeyCode.upArrow, modifiers: [.control]),
    Rule(shortcut: .controlDown, keyCode: MacVirtualKeyCode.downArrow, modifiers: [.control]),
    Rule(
      shortcut: .controlCommandQ,
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.control, .command]
    ),
  ]

  public static func decision(
    keyCode: UInt16,
    modifiers: InputModifierMask
  ) -> InputFilterDecision {
    let distinguishing = modifiers.intersection(.distinguishing)
    for rule in rules where rule.keyCode == keyCode && rule.modifiers == distinguishing {
      return .suppress(rule.shortcut)
    }
    return .allow
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
