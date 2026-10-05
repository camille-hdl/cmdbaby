import Foundation

/// Langue demandée pour BabyWorks. *Système* suit le Mac.
public enum AppLanguagePreference: String, CaseIterable, Equatable, Sendable {
  case system
  case english
  case french
}
