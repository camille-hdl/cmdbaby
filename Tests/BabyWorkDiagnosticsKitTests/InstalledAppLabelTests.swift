import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le nom affiché l’emporte sur le nom du bundle")
func installedAppNamePrefersDisplayName() {
  #expect(
    InstalledAppLabel.name(displayName: "CmdBaby (sandbox)", bundleName: "BabyWorksSandbox")
      == "CmdBaby (sandbox)"
  )
  #expect(InstalledAppLabel.name(displayName: "  ", bundleName: "CmdBaby") == "CmdBaby")
  #expect(InstalledAppLabel.name(displayName: nil, bundleName: nil) == nil)
}

@Test("La version est « courte (build) », absente si l’un des deux manque")
func installedAppVersionJoinsShortAndBuild() {
  #expect(InstalledAppLabel.version(shortVersion: "0.1.0", build: "1") == "0.1.0 (1)")
  #expect(InstalledAppLabel.version(shortVersion: "2.4", build: "9") == "2.4 (9)")
  #expect(InstalledAppLabel.version(shortVersion: nil, build: "1") == nil)
  #expect(InstalledAppLabel.version(shortVersion: "0.1.0", build: nil) == nil)
  #expect(InstalledAppLabel.version(shortVersion: "  ", build: "1") == nil)
  #expect(InstalledAppLabel.version(shortVersion: "", build: "") == nil)
}
