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

@Test("Un JSON v1 sans exits donne un minuteur de 20 minutes")
func configurationVersionOneWithoutExitsDefaultsTimeLimitToTwentyMinutes() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(
      #"""
      {"schemaVersion":1,"mode":"galaxy","launchAtLogin":true}
      """#.utf8
    )
  )
  #expect(decoded.exits.timeLimitMinutes == 20)
  #expect(decoded == BabyWorksConfiguration(schemaVersion: 1, mode: .galaxy, launchAtLogin: true))
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

@Test("Un champ de minuteur illisible reprend 20 minutes et conserve le mode")
func configurationInvalidTimeLimitFieldDecodesToTwentyMinutes() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"mode":"galaxy","exits":{"timeLimitMinutes":"long"}}"#.utf8)
  )
  #expect(decoded.exits.timeLimitMinutes == 20)
  #expect(decoded.mode == .galaxy)
}

@Test("Un JSON v1 sans champ nouveau se relit à l’identique")
func configurationVersionOneJSONDecodesIdentically() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(
      #"""
      {"schemaVersion":1,"mode":"galaxy","launchAtLogin":true}
      """#.utf8
    )
  )
  #expect(decoded == BabyWorksConfiguration(schemaVersion: 1, mode: .galaxy, launchAtLogin: true))
}

@Test("Une config encodée se relit à l’identique")
func configurationRoundTripsThroughJSON() throws {
  let original = BabyWorksConfiguration(mode: .galaxy, launchAtLogin: true)
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
    from: Data(#"{"mode":"galaxy"}"#.utf8)
  )
  #expect(partial == BabyWorksConfiguration(mode: .galaxy))
}

@Test("Un mode JSON inconnu replie sur Océan et conserve les autres champs")
func configurationUnknownModeDecodesToOcean() throws {
  let decoded = try JSONDecoder().decode(
    BabyWorksConfiguration.self,
    from: Data(#"{"mode":"leaf","launchAtLogin":true}"#.utf8)
  )
  #expect(decoded == BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
}
