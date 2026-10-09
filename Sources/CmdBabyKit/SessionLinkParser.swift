import Foundation

/// Échec de lecture d’un lien `cmdbaby://session/start`. Pas de lancement.
public enum SessionLinkFailure: Error, Equatable, Sendable {
  case unknownScheme
  case unknownPath
  case unknownMode
  case durationNotInteger
  case durationOutOfBounds
  case duplicateParameter

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
    if hasDuplicate(named: "mode", in: items) || hasDuplicate(named: "minutes", in: items) {
      return .failure(.duplicateParameter)
    }

    var mode: KioskPlayModeID?
    if let rawMode = items.first(where: { $0.name == "mode" })?.value {
      guard let resolved = KioskPlayModeCatalog.resolve(rawMode) else {
        return .failure(.unknownMode)
      }
      mode = resolved
    }

    var durationMinutes: Int?
    if let rawMinutes = items.first(where: { $0.name == "minutes" })?.value {
      guard let minutes = Int(rawMinutes) else {
        return .failure(.durationNotInteger)
      }
      guard AdultExitSettings.timeLimitRange.contains(minutes) else {
        return .failure(.durationOutOfBounds)
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
