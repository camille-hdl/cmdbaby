import Foundation

/// Langue demandée pour CmdBaby. *Système* suit le Mac.
public enum AppLanguagePreference: String, CaseIterable, Equatable, Sendable {
  case system
  case english
  case french
}
