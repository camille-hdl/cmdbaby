import AppKit
import BabyWorkDiagnosticsKit
import Carbon
import Foundation

/// État de session publié vers l’interface.
final class DiagnosticsPublishedState: @unchecked Sendable {
  var filterStatus: InputFilterStatus = .inactive
  var kioskState = KioskSessionState()
}

@MainActor
final class DiagnosticsSessionModel {
  let ui: DiagnosticsPublishedState
  private let environment: AppKitKioskEnvironment
  private let kioskController: KioskSessionController
  private weak var terminationDelegate: BabyWorksAppDelegate?
  private var kioskTask: Task<Void, Never>?
  private var presentActivationFailure: ((KioskSessionError) -> Void)?
  private var endRequest: KioskEndRequest?

  init(terminationGate: TerminationGate = TerminationGate()) {
    let environment = AppKitKioskEnvironment(terminationGate: terminationGate)
    self.environment = environment
    kioskController = KioskSessionController(services: environment)
    ui = DiagnosticsPublishedState()
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
      Task { @MainActor in
        self?.ui.filterStatus = status
      }
    }
    environment.onAdultExit = { [weak self] kind in
      Task { @MainActor in
        self?.handleAdultExit(kind)
      }
    }
  }

  func attachTerminationDelegate(_ delegate: BabyWorksAppDelegate) {
    terminationDelegate = delegate
  }

  func attachParentChrome(
    hide: @escaping () -> Void,
    presentActivationFailure: @escaping (KioskSessionError) -> Void
  ) {
    environment.onHideDiagnosticInterface = hide
    self.presentActivationFailure = presentActivationFailure
  }

  func startKiosk() {
    guard kioskTask == nil else { return }
    switch kioskController.state.phase {
    case .configuration, .failed:
      break
    case .preparing, .activating, .active, .stopping:
      return
    }
    switch ui.kioskState.phase {
    case .configuration, .failed:
      break
    case .preparing, .activating, .active, .stopping:
      return
    }

    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    kioskController.injectedFailure = nil
    environment.terminationGate.setBlocked(true)
    endRequest = nil

    kioskTask = Task { [weak self] in
      guard let self else { return }
      let state = await self.kioskController.activate()
      if state.phase == .stopping {
        let request = self.endRequest ?? .adultExit(state.lastExitKind ?? .passphrase)
        self.completeExit(request)
        return
      }
      self.ui.kioskState = state
      self.kioskTask = nil
      switch state.phase {
      case .configuration, .failed:
        self.environment.terminationGate.setBlocked(false)
        self.ui.filterStatus = .inactive
      case .preparing, .activating, .active, .stopping:
        break
      }
      if state.phase == .failed, let error = state.lastError {
        self.presentActivationFailure?(error)
      }
    }
  }

  func quit() {
    switch kioskController.state.phase {
    case .preparing, .activating:
      endRequest = .explicitQuit
      kioskController.beginStopping()
      ui.kioskState = kioskController.state
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
      ui.kioskState = kioskController.state
    case .active, .failed:
      completeExit(.adultExit(kind))
    }
  }

  private func completeExit(_ request: KioskEndRequest) {
    ui.kioskState = kioskController.deactivate(request)
    ui.filterStatus = .inactive
    environment.terminationGate.setBlocked(false)
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
