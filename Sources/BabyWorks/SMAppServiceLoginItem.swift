import BabyWorkDiagnosticsKit
import ServiceManagement

/// Login Item `SMAppService.mainApp` — chemin nosandbox, sans helper.
struct SMAppServiceLoginItem: LoginItemRegistration {
  var isRegistered: Bool {
    switch SMAppService.mainApp.status {
    case .enabled, .requiresApproval:
      true
    case .notRegistered, .notFound:
      false
    @unknown default:
      false
    }
  }

  func register() throws {
    try SMAppService.mainApp.register()
  }

  func unregister() throws {
    try SMAppService.mainApp.unregister()
  }
}
