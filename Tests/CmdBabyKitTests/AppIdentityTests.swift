import Foundation
import Testing

@testable import CmdBabyKit

@Test("AppIdentity fournit le nom, le bundle ID, le dossier et le sous-système des journaux")
func appIdentityValues() {
  #expect(AppIdentity.displayName == "CmdBaby")
  #expect(AppIdentity.bundleIdentifier == "app.cmdbaby.CmdBaby")
  #expect(AppIdentity.supportDirectoryName == "CmdBaby")
  #expect(AppIdentity.logSubsystem == "app.cmdbaby.CmdBaby")
}

@Test("L’Info.plist porte le nom, le bundle ID et l’exécutable d’AppIdentity")
func infoPlistMatchesAppIdentity() throws {
  let plistURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Resources/CmdBaby-Info.plist")
  let plist = try #require(NSDictionary(contentsOf: plistURL) as? [String: Any])

  #expect(plist["CFBundleName"] as? String == AppIdentity.displayName)
  #expect(plist["CFBundleDisplayName"] as? String == AppIdentity.displayName)
  #expect(plist["CFBundleExecutable"] as? String == AppIdentity.displayName)
  #expect(plist["CFBundleIdentifier"] as? String == AppIdentity.bundleIdentifier)
}
