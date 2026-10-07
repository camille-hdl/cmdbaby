import AppKit
import CmdBabyKit
import Combine
import Sparkle

/// Mises à jour par Sparkle, avec la fenêtre standard. Rien ne s’affiche ni ne s’installe
/// pendant une session : la vérification est refusée, puis relancée à la fin de la session.
@MainActor
final class UpdateController: NSObject, ObservableObject {
  private var controller: SPUStandardUpdaterController?
  private let isSessionActive: () -> Bool
  private var checkDeferred = false
  private var sessionObserver: AnyCancellable?

  /// Démarre Sparkle seulement dans un `.app` : `swift run` et les tests n’ont pas d’Info.plist.
  init(session: DiagnosticsSessionModel) {
    isSessionActive = { [weak session] in session?.isTerminationBlocked ?? false }
    super.init()
    let startsUpdater = Bundle.main.bundleURL.pathExtension == "app"
      && Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
    guard startsUpdater else { return }
    controller = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: self,
      userDriverDelegate: nil
    )
    sessionObserver = session.$isTerminationBlocked
      .removeDuplicates()
      .sink { [weak self] active in
        guard !active else { return }
        Task { @MainActor in self?.sessionDidEnd() }
      }
  }

  var isAvailable: Bool { controller != nil }

  /// Réglages › Général.
  var automaticallyChecksForUpdates: Bool {
    get { controller?.updater.automaticallyChecksForUpdates ?? false }
    set {
      objectWillChange.send()
      controller?.updater.automaticallyChecksForUpdates = newValue
    }
  }

  @objc func checkForUpdates(_ sender: Any?) {
    controller?.checkForUpdates(sender)
  }

  private func sessionDidEnd() {
    guard checkDeferred, let updater = controller?.updater else { return }
    checkDeferred = false
    updater.checkForUpdatesInBackground()
  }

  fileprivate func mayPerformCheck() -> Bool {
    guard UpdatePresentationPolicy.allowsPresentation(sessionActive: isSessionActive()) else {
      checkDeferred = true
      return false
    }
    return true
  }
}

extension UpdateController: SPUUpdaterDelegate {
  nonisolated func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
    let allowed = MainActor.assumeIsolated { self.mayPerformCheck() }
    guard allowed else {
      throw NSError(
        domain: "\(AppIdentity.bundleIdentifier).updates",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Vérification reportée à la fin de la session."]
      )
    }
  }
}
