import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("fr-FR se lit français, en-GB anglais, de et l’absence comme Système")
func readingAppleLanguagesMapsToThePreference() {
  #expect(AppLanguageSettings(store: FakeAppLanguageStore(["fr-FR"])).current() == .french)
  #expect(AppLanguageSettings(store: FakeAppLanguageStore(["en-GB"])).current() == .english)
  #expect(AppLanguageSettings(store: FakeAppLanguageStore(["de"])).current() == .system)
  #expect(AppLanguageSettings(store: FakeAppLanguageStore(nil)).current() == .system)
}

@Test("English écrit en, Français écrit fr, Système supprime la clé")
func applyingAPreferenceWritesAppleLanguages() {
  let english = FakeAppLanguageStore(nil)
  let englishSettings = AppLanguageSettings(store: english)
  englishSettings.apply(.english)
  #expect(english.appleLanguages() == ["en"])
  #expect(englishSettings.current() == .english)

  let french = FakeAppLanguageStore(["en-GB"])
  let frenchSettings = AppLanguageSettings(store: french)
  frenchSettings.apply(.french)
  #expect(french.appleLanguages() == ["fr"])
  #expect(frenchSettings.current() == .french)

  let system = FakeAppLanguageStore(["fr-FR"])
  let systemSettings = AppLanguageSettings(store: system)
  systemSettings.apply(.system)
  #expect(system.appleLanguages() == nil)
  #expect(systemSettings.current() == .system)
}

private final class FakeAppLanguageStore: AppLanguageStore, @unchecked Sendable {
  private var languages: [String]?

  init(_ languages: [String]?) {
    self.languages = languages
  }

  func appleLanguages() -> [String]? {
    languages
  }

  func setAppleLanguages(_ languages: [String]?) {
    self.languages = languages
  }
}
