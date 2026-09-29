import AppKit
import BabyWorkDiagnosticsKit
import Carbon
import Foundation

/// État de session. Hors `@MainActor` : des observateurs AppKit peuvent le lire
/// hors de l’exécuteur (`swift_task_isCurrentExecutor`).
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
      DispatchQueue.main.async {
        MainActor.assumeIsolated {
          self?.ui.filterStatus = status
        }
      }
    }

    let stopFlag = kioskController.externalStop
    let gate = environment.terminationGate
    environment.emergency.onBeginStop = { [weak self] kind in
      stopFlag.mark(kind)
      Task { @MainActor in
        self?.beginAdultExit(kind)
      }
    }
    environment.emergency.syncModel = { [weak self] kind in
      stopFlag.mark(kind)
      Task { @MainActor in
        self?.handleAdultExit(kind)
      }
    }
    environment.emergency.unblock = {
      gate.setBlocked(false)
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
    guard !environment.emergency.isTeardownInFlight() else { return }
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
    environment.emergency.arm()

    kioskTask = Task { [weak self] in
      guard let self else { return }
      _ = await self.kioskController.activate()
      let state = self.kioskController.state
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
    environment.emergency.quit()
  }

  private func beginAdultExit(_ kind: AdultExitKind) {
    kioskController.beginStopping(exitKind: kind)
    ui.kioskState = kioskController.state
  }

  func handleAdultExit(_ kind: AdultExitKind) {
    switch kioskController.state.phase {
    case .preparing, .activating, .active, .stopping:
      ui.kioskState = kioskController.deactivate(exitKind: kind)
      ui.filterStatus = .inactive
      environment.terminationGate.setBlocked(false)
    case .configuration, .failed:
      stopFilter()
    }
    environment.emergency.markTeardownFinished()
    LifecycleLogRecorder.shared.emit(
      .statusItemAlive(terminationDelegate?.isStatusItemInstalled() ?? false)
    )
  }

  private func stopFilter() {
    environment.stopInputFilter()
    ui.filterStatus = .inactive
  }
}
