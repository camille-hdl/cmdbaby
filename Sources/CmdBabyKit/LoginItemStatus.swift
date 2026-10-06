/// Statut du Login Item (`SMAppService.mainApp.status`), sans ServiceManagement.
public enum LoginItemStatus: Equatable, Sendable {
  case enabled
  case requiresApproval
  case notRegistered
  case notFound
}
