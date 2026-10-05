import BabyWorkDiagnosticsKit
import ServiceManagement

/// Login Item `SMAppService.mainApp` — chemin nosandbox, sans helper.
struct SMAppServiceLoginItem: LoginItemRegistration {
  var status: LoginItemStatus {
    switch SMAppService.mainApp.status {
    case .enabled:
      .enabled
    case .requiresApproval:
      .requiresApproval
    case .notRegistered:
      .notRegistered
    case .notFound:
      .notFound
    @unknown default:
      .notRegistered
    }
  }

  var isRegistered: Bool {
    switch status {
    case .enabled, .requiresApproval:
      true
    case .notRegistered, .notFound:
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
