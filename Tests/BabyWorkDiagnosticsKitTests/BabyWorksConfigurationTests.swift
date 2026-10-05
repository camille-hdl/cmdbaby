import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("La config par défaut est le mode Océan, sans lancement à l’ouverture")
func configurationDefaultsToOceanWithoutLaunchAtLogin() {
  let configuration = BabyWorksConfiguration()
  #expect(configuration.schemaVersion == 1)
  #expect(configuration.mode == .ocean)
  #expect(configuration.launchAtLogin == false)
}

@Test("Une configuration vide donne un minuteur de 3 minutes")
func emptyConfigurationDecodesToAThreeMinuteTimeLimit() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data("{}".utf8)
  )
  #expect(decoded.exits.timeLimitMinutes == 3)
}

@Test("Une durée de 20 minutes déjà enregistrée est conservée")
func savedTimeLimitOfTwentyMinutesIsKept() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":20}}"#.utf8)
  )
  #expect(decoded.exits.timeLimitMinutes == 20)
}

@Test("Un JSON v1 sans exits donne un minuteur de 3 minutes")
func configurationVersionOneWithoutExitsDefaultsTimeLimitToThreeMinutes() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(
      #"""
      {"schemaVersion":1,"mode":"starship","launchAtLogin":true}
      """#.utf8
    )
  )
  #expect(decoded.exits.timeLimitMinutes == 3)
  #expect(decoded == BabyWorksConfiguration(schemaVersion: 1, mode: .starship, launchAtLogin: true))
}

@Test("Une méthode inconnue est ignorée et les méthodes connues restent")
func configurationUnknownExitMethodIsIgnored() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"enabledMethods":["shiftEscape","inconnu"]}}"#.utf8)
  )
  #expect(decoded.exits.enabledMethods == [.shiftEscape])
}

@Test("enabledMethods absent ou vide active les trois sorties manuelles")
func configurationMissingOrEmptyEnabledMethodsEnablesAllManualExits() throws {
  let absent = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":20}}"#.utf8)
  )
  let empty = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"enabledMethods":[]}}"#.utf8)
  )
  #expect(absent.exits.enabledMethods == AdultExitSettings.defaultEnabledMethods)
  #expect(empty.exits.enabledMethods == AdultExitSettings.defaultEnabledMethods)
}

@Test("Une phrase absente ou invalide sur disque redevient parent")
func configurationMissingOrInvalidPassphraseDefaultsToParent() throws {
  let absent = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":45}}"#.utf8)
  )
  let tooShort = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":45,"passphrase":"ab"}}"#.utf8)
  )
  let notAString = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":45,"passphrase":12}}"#.utf8)
  )

  #expect(absent.exits.passphrase == .defaultValue)
  #expect(absent.exits.passphrase.value == "parent")
  #expect(absent.exits.timeLimitMinutes == 45)
  #expect(tooShort.exits.passphrase.value == "parent")
  #expect(tooShort.exits.timeLimitMinutes == 45)
  #expect(notAString.exits.passphrase.value == "parent")
}

@Test("Un minuteur hors bornes relu sur disque est ramené entre 1 et 120")
func configurationOutOfRangeTimeLimitIsClamped() throws {
  let tooLow = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":0}}"#.utf8)
  )
  let tooHigh = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"exits":{"timeLimitMinutes":500}}"#.utf8)
  )
  #expect(tooLow.exits.timeLimitMinutes == 1)
  #expect(tooHigh.exits.timeLimitMinutes == 120)
}

@Test("Un champ de minuteur illisible reprend 3 minutes et conserve le mode")
func configurationInvalidTimeLimitFieldDecodesToThreeMinutes() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"mode":"starship","exits":{"timeLimitMinutes":"long"}}"#.utf8)
  )
  #expect(decoded.exits.timeLimitMinutes == 3)
  #expect(decoded.mode == .starship)
}

@Test("Un JSON v1 sans champ nouveau se relit à l’identique")
func configurationVersionOneJSONDecodesIdentically() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(
      #"""
      {"schemaVersion":1,"mode":"starship","launchAtLogin":true}
      """#.utf8
    )
  )
  #expect(decoded == BabyWorksConfiguration(schemaVersion: 1, mode: .starship, launchAtLogin: true))
}

@Test("Une config encodée se relit à l’identique")
func configurationRoundTripsThroughJSON() throws {
  let original = BabyWorksConfiguration(mode: .starship, launchAtLogin: true)
  let data = try JSONEncoder().encode(original)
  let decoded = try JSONDecoder().decode(BabyWorksConfiguration.self, from: data)
  #expect(decoded == original)
}

@Test("Les champs JSON manquants reprennent les défauts")
func configurationMissingFieldsDecodeToDefaults() throws {
  let empty = try JSONDecoder().decode(BabyWorksConfiguration.self, from: Data("{}".utf8))
  #expect(empty == BabyWorksConfiguration())

  let partial = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"mode":"starship"}"#.utf8)
  )
  #expect(partial == BabyWorksConfiguration(mode: .starship))
}

@Test("Une configuration enregistrée en Galaxie ouvre le mode Vaisseau")
func retiredGalaxyConfigurationOpensStarship() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"schemaVersion":1,"mode":"galaxy","launchAtLogin":true}"#.utf8)
  )
  #expect(decoded.mode == .starship)
}

@Test("Un mode JSON inconnu replie sur Océan et conserve les autres champs")
func configurationUnknownModeDecodesToOcean() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"mode":"leaf","launchAtLogin":true}"#.utf8)
  )
  #expect(decoded == BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
}
