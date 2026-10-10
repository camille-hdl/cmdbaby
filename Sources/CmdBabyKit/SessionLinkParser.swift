import Foundation

/// Échec de lecture d’un lien `cmdbaby://session/start`. Pas de lancement.
public enum SessionLinkFailure: Error, Equatable, Sendable {
  case unknownScheme
  case unknownPath
  case unknownMode
  case durationNotInteger
  case durationOutOfBounds
  case duplicateParameter
  case unknownParameter

  public func message(in table: L10nTable = .current) -> String {
    switch self {
    case .unknownScheme:
      table("alert.link.unknownScheme")
    case .unknownPath:
      table("alert.link.unknownPath")
    case .unknownMode:
      table("alert.link.unknownMode")
    case .durationNotInteger:
      table("alert.link.durationNotInteger")
    case .durationOutOfBounds:
      table("shortcuts.startSession.invalidParameter")
    case .duplicateParameter:
      table("alert.link.duplicateParameter")
    case .unknownParameter:
      table("alert.link.unknownParameter")
    }
  }
}

/// Traduit une URL en requête de lancement. Seul `cmdbaby://session/start` existe.
public enum SessionLinkParser {
  public static func parse(_ url: URL) -> Result<SessionLaunchRequest, SessionLinkFailure> {
    guard url.scheme?.lowercased() == "cmdbaby" else {
      return .failure(.unknownScheme)
    }
    let host = url.host?.lowercased()
    let path = url.path.lowercased()
    guard host == "session", path == "/start" || path == "/start/" else {
      return .failure(.unknownPath)
    }

    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let knownParameters: Set<String> = ["mode", "minutes"]
    if items.contains(where: { !knownParameters.contains($0.name) }) {
      return .failure(.unknownParameter)
    }
    if hasDuplicate(named: "mode", in: items) || hasDuplicate(named: "minutes", in: items) {
      return .failure(.duplicateParameter)
    }

    var mode: KioskPlayModeID?
    if let modeItem = items.first(where: { $0.name == "mode" }) {
      guard let rawMode = modeItem.value, let resolved = KioskPlayModeCatalog.resolve(rawMode) else {
        return .failure(.unknownMode)
      }
      mode = resolved
    }

    var durationMinutes: Int?
    if let minutesItem = items.first(where: { $0.name == "minutes" }) {
      guard let rawMinutes = minutesItem.value, let minutes = Int(rawMinutes) else {
        return .failure(.durationNotInteger)
      }
      durationMinutes = minutes
    }

    return .success(
      SessionLaunchRequest(origin: .link, mode: mode, durationMinutes: durationMinutes)
    )
  }

  private static func hasDuplicate(named name: String, in items: [URLQueryItem]) -> Bool {
    items.filter { $0.name == name }.count > 1
  }
}
