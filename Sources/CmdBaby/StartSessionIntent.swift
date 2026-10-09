import AppIntents

/// Action Raccourcis « Lancer une session », sans paramètre.
///
/// App Intents n’accepte que des littéraux extraits à la compilation, pas `L10nTable`.
/// Le même texte est dans `L10nTable` (`shortcuts.startSession.*`) et dans le catalogue
/// du bundle principal (`Contents/Resources/*.lproj`), que Raccourcis consulte.
struct StartSessionIntent: AppIntent {
  static let title: LocalizedStringResource = "Start a Session"
  static let description = IntentDescription("Starts a session with your saved settings.")

  /// Lance le processus s’il ne tourne pas, puis exécute l’action dans l’app.
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    try await MainActor.run {
      guard let delegate = CmdBabyAppDelegate.running else {
        throw StartSessionAppUnavailable()
      }
      delegate.startSession(nil)
    }
    return .result()
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
      ],
      shortTitle: "Start a Session"
    )
  }
}
