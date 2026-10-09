import AppKit
import CmdBabyKit
import Carbon
import Combine
import Foundation

@MainActor
final class DiagnosticsSessionModel: ObservableObject {
  private(set) var filterStatus: InputFilterStatus = .inactive
  private(set) var kioskState = KioskSessionState()
  @Published private(set) var isTerminationBlocked = false

  private let environment: AppKitKioskEnvironment
  private let kioskController: KioskSessionController
  private weak var terminationDelegate: CmdBabyAppDelegate?
  private var kioskTask: Task<SessionLaunchDecision, Never>?
  private var presentActivationFailure: ((KioskSessionError) -> Void)?
  private var endRequest: KioskEndRequest?

  init() {
    let environment = AppKitKioskEnvironment()
    self.environment = environment
    kioskController = KioskSessionController(services: environment)
    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    DistributedNotificationCenter.default().addObserver(
      forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
      object: nil,
      queue: .main
    ) { _ in
      Task { @MainActor in
        KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
      }
    }

    environment.onFilterStatus = { [weak self] status in
      Task { @MainActor [weak self] in
        self?.filterStatus = status
      }
    }
    environment.onAdultExit = { [weak self] kind in
      Task { @MainActor in
        self?.handleAdultExit(kind)
      }
    }
  }

  func attachTerminationDelegate(_ delegate: CmdBabyAppDelegate) {
    terminationDelegate = delegate
  }

  func attachParentChrome(
    hide: @escaping () -> Void,
    presentActivationFailure: @escaping (KioskSessionError) -> Void
  ) {
    environment.onHideDiagnosticInterface = hide
    self.presentActivationFailure = presentActivationFailure
  }

  /// Pendant une session, un lien ne montre rien.
  var suppressesLinkFeedback: Bool {
    phaseBlocksAnotherLaunch(launchPhase())
  }

  func startKiosk(_ request: SessionLaunchRequest) async -> SessionLaunchDecision {
    let phase = launchPhase()
    let saved = CmdBabyConfigurationStore().load()
    // Le contrôle clavier est plus bas. Ici, seuls le repos, l’autorisation du lien
    // et la durée peuvent déjà décider.
    switch SessionLaunchDecision.evaluate(
      request: request,
      phase: phase,
      check: .allowed,
      linkLaunchAllowed: saved.linkLaunchAllowed
    ) {
    case .alreadyInProgress:
      return .alreadyInProgress
    case .linkNotAllowed:
      return .linkNotAllowed
    case .invalidParameter:
      return .invalidParameter
    case .launch, .refused:
      break
    }

    let configuration: CmdBabyConfiguration
    switch request.effectiveConfiguration(from: saved) {
    case .invalidParameter:
      return .invalidParameter
    case .ready(let effective):
      configuration = effective
    }

    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    let typability = PassphraseTypability.check(
      configuration.exits.passphrase,
      layoutLetters: KeyboardLayoutLetter.shared.snapshot()
    )
    let check = SessionLaunchCheck.evaluate(
      exits: configuration.exits,
      typability: typability,
      secureInputActive: IsSecureEventInputEnabled()
    )
    switch SessionLaunchDecision.evaluate(
      request: request,
      phase: phase,
      check: check,
      linkLaunchAllowed: saved.linkLaunchAllowed
    ) {
    case .alreadyInProgress:
      return .alreadyInProgress
    case .linkNotAllowed:
      return .linkNotAllowed
    case .refused(let error):
      reportActivationFailure(error)
      return .refused(error)
    case .invalidParameter:
      return .invalidParameter
    case .launch:
      break
    }

    kioskController.injectedFailure = nil
    isTerminationBlocked = true
    endRequest = nil
    environment.prepareSession(configuration)

    let task = Task { [weak self] () -> SessionLaunchDecision in
      guard let self else { return .alreadyInProgress }
      let state = await self.kioskController.activate(origin: request.origin)
      if state.phase == .stopping {
        let end = self.endRequest ?? .adultExit(state.lastExitKind ?? .passphrase)
        self.completeExit(end)
        return .launch
      }
      self.kioskState = state
      self.kioskTask = nil
      switch state.phase {
      case .configuration, .failed:
        self.isTerminationBlocked = false
        self.filterStatus = .inactive
      case .preparing, .activating, .active, .stopping:
        break
      }
      if state.phase == .failed, let error = state.lastError {
        self.reportActivationFailure(error)
        return .refused(error)
      }
      return .launch
    }
    kioskTask = task
    return await task.value
  }

  /// Phase vue par la décision. Une activation déjà lancée compte comme occupée,
  /// même avant que le contrôleur ait quitté `.configuration`.
  private func launchPhase() -> KioskSessionPhase {
    if kioskTask != nil { return .activating }
    for phase in [kioskController.state.phase, kioskState.phase] {
      if phaseBlocksAnotherLaunch(phase) { return phase }
    }
    return kioskController.state.phase
  }

  private func phaseBlocksAnotherLaunch(_ phase: KioskSessionPhase) -> Bool {
    switch phase {
    case .preparing, .activating, .active, .stopping:
      true
    case .configuration, .failed:
      false
    }
  }

  /// L’alerte est modale : au tour suivant, le menu ou les Réglages sont déjà refermés.
  private func reportActivationFailure(_ error: KioskSessionError) {
    Task { @MainActor [weak self] in
      self?.presentActivationFailure?(error)
    }
  }

  func quit() {
    switch kioskController.state.phase {
    case .preparing, .activating:
      endRequest = .explicitQuit
      kioskController.beginStopping()
      kioskState = kioskController.state
    case .stopping where kioskTask != nil:
      endRequest = .explicitQuit
    default:
      completeExit(.explicitQuit)
    }
  }

  func handleAdultExit(_ kind: AdultExitKind) {
    switch kioskController.state.phase {
    case .configuration, .stopping:
      return
    case .preparing, .activating:
      endRequest = .adultExit(kind)
      kioskController.beginStopping(exitKind: kind)
      kioskState = kioskController.state
    case .active, .failed:
      completeExit(.adultExit(kind))
    }
  }

  private func completeExit(_ request: KioskEndRequest) {
    kioskState = kioskController.deactivate(request)
    filterStatus = .inactive
    isTerminationBlocked = false
    kioskTask = nil
    if request.terminatesProcess {
      NSApp.terminate(nil)
    } else {
      LifecycleLogRecorder.shared.emit(
        .statusItemAlive(terminationDelegate?.isStatusItemInstalled() ?? false)
      )
    }
  }
}
