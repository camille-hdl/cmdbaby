import AppIntents
import CmdBabyKit

/// Action Raccourcis « Lancer une session ».
///
/// Mode et durée sont optionnels et ne valent que pour cette session.
/// App Intents n’accepte que des littéraux extraits à la compilation, pas `L10nTable`.
/// Raccourcis affiche le catalogue du bundle principal (`Contents/Resources/*.lproj`).
struct StartSessionIntent: AppIntent {
  static let title: LocalizedStringResource = "Start a Session"
  static let description = IntentDescription("Starts a session with your saved settings.")

  /// Lance le processus s’il ne tourne pas, puis exécute l’action dans l’app.
  static let openAppWhenRun = true

  @Parameter(title: "Mode")
  var mode: StartSessionMode?

  @Parameter(title: "Duration", description: "Minutes, from 1 to 120")
  var minutes: Int?

  static var parameterSummary: some ParameterSummary {
    When(\.$mode, .hasAnyValue) {
      When(\.$minutes, .hasAnyValue) {
        Summary("Start a \(\.$mode) session for \(\.$minutes) minutes")
      } otherwise: {
        Summary("Start a \(\.$mode) session")
      }
    } otherwise: {
      When(\.$minutes, .hasAnyValue) {
        Summary("Start a session for \(\.$minutes) minutes")
      } otherwise: {
        Summary("Start a session")
      }
    }
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let requestedMode = mode?.playMode
    let requestedMinutes = minutes
    guard let delegate = await MainActor.run(body: { CmdBabyAppDelegate.running }) else {
      throw StartSessionAppUnavailable()
    }
    let decision = await delegate.launchSession(
      SessionLaunchRequest(
        origin: .shortcuts,
        mode: requestedMode,
        durationMinutes: requestedMinutes
      )
    )
    switch decision {
    case .launch, .alreadyInProgress:
      return .result(dialog: IntentDialog(resolved: decision.message()))
    case .refused, .invalidParameter, .linkNotAllowed:
      throw SessionLaunchCallerError(message: decision.message())
    }
  }
}

/// Modes de l’action, dans l’ordre du catalogue.
/// `init` est exhaustif : un mode ajouté à `KioskPlayModeID` casse la compilation.
enum StartSessionMode: String, AppEnum {
  case ocean
  case terminal
  case starship

  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Mode")

  static let caseDisplayRepresentations: [StartSessionMode: DisplayRepresentation] = [
    .ocean: "Ocean",
    .terminal: "Terminal",
    .starship: "Starship",
  ]

  init(_ id: KioskPlayModeID) {
    switch id {
    case .ocean:
      self = .ocean
    case .terminal:
      self = .terminal
    case .starship:
      self = .starship
    }
  }

  var playMode: KioskPlayModeID {
    switch self {
    case .ocean:
      .ocean
    case .terminal:
      .terminal
    case .starship:
      .starship
    }
  }
}

/// Erreur déjà traduite par `L10nTable`. La chaîne est le texte, pas une clé du catalogue.
private struct SessionLaunchCallerError: Error, CustomLocalizedStringResourceConvertible {
  var localizedStringResource: LocalizedStringResource

  init(message: String) {
    localizedStringResource = LocalizedStringResource(stringLiteral: message)
  }
}

extension IntentDialog {
  /// `stringLiteral` sert de clé ; une phrase déjà résolue s’affiche telle quelle.
  fileprivate init(resolved message: String) {
    self.init(stringLiteral: message)
  }
}

/// Le délégué est posé dans `init`, avant qu’une action puisse s’exécuter.
private struct StartSessionAppUnavailable: Error, Sendable {}

/// Rend l’action trouvable dans Spotlight. Chaque phrase contient le nom de l’app.
struct CmdBabyShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartSessionIntent(),
      phrases: [
        "Start a Session with \(.applicationName)",
        "Start a \(\.$mode) session with \(.applicationName)",
      ],
      shortTitle: "Start a Session"
    )
  }
}
