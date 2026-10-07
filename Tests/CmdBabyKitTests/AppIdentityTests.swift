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

private func repositoryFile(_ path: String) -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent(path)
}

@Test("L’Info.plist est celui d’une app distribuable")
func infoPlistIsDistributable() throws {
  let plist = try #require(
    NSDictionary(contentsOf: repositoryFile("Resources/CmdBaby-Info.plist")) as? [String: Any]
  )
  #expect(plist["NSHumanReadableCopyright"] as? String == "© 2026 Camille Hodoul")
  #expect(plist["LSMinimumSystemVersion"] as? String == "13.0")
  #expect(plist["LSApplicationCategoryType"] as? String == "public.app-category.education")
  #expect(plist["NSHighResolutionCapable"] as? Bool == true)
  #expect(plist["NSInputMonitoringUsageDescription"] == nil)
  #expect(plist["NSAppTransportSecurity"] == nil)
  #expect(plist["CFBundleIconName"] as? String == "AppIcon")
  #expect(plist["CFBundleIconFile"] as? String == "AppIcon")
  // Sparkle (#102) : flux signé, vérification avant extraction, rien d’automatique ni de profilage.
  #expect(plist["SUFeedURL"] as? String == "https://cmdbaby.app/appcast.xml")
  #expect(plist["SURequireSignedFeed"] as? Bool == true)
  #expect(plist["SUVerifyUpdateBeforeExtraction"] as? Bool == true)
  #expect(plist["SUAutomaticallyUpdate"] as? Bool == false)
  #expect(plist["SUEnableJavaScript"] as? Bool == false)
  #expect(plist["SUEnableSystemProfiling"] as? Bool == false)
  #expect(plist["SUEnableInstallerLauncherService"] == nil)
  #expect(plist["SUEnableDownloaderService"] == nil)
  let releaseEnv = try String(contentsOf: repositoryFile("scripts/release.env"), encoding: .utf8)
  #expect(releaseEnv.contains("SPARKLE_PUBLIC_KEY=\(plist["SUPublicEDKey"] as? String ?? "?")"))
  #expect(FileManager.default.fileExists(atPath: repositoryFile("Resources/AppIcon.icon/icon.json").path))
}

@Test("Le manifeste de confidentialité déclare l’absence de suivi et les API à motif")
func privacyManifestDeclaresRequiredReasons() throws {
  let manifest = try #require(
    NSDictionary(contentsOf: repositoryFile("Resources/PrivacyInfo.xcprivacy")) as? [String: Any]
  )
  #expect(manifest["NSPrivacyTracking"] as? Bool == false)
  #expect((manifest["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)
  #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
  let apis = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
  let reasons = Dictionary(
    uniqueKeysWithValues: apis.map {
      ($0["NSPrivacyAccessedAPIType"] as? String ?? "", $0["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? [])
    }
  )
  #expect(reasons["NSPrivacyAccessedAPICategoryUserDefaults"] == ["CA92.1"])
  #expect(reasons["NSPrivacyAccessedAPICategoryFileTimestamp"] == ["C617.1"])
  #expect(reasons["NSPrivacyAccessedAPICategorySystemBootTime"] == ["35F9.1"])
}
