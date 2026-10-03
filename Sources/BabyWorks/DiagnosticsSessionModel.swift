import AppKit
import BabyWorkDiagnosticsKit
import Carbon
import Foundation

@MainActor
final class DiagnosticsSessionModel {
  private(set) var filterStatus: InputFilterStatus = .inactive
  private(set) var kioskState = KioskSessionState()
  private(set) var isTerminationBlocked = false

  private let environment: AppKitKioskEnvironment
  private let kioskController: KioskSessionController
  private weak var terminationDelegate: BabyWorksAppDelegate?
  private var kioskTask: Task<Void, Never>?
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
    switch kioskState.phase {
    case .configuration, .failed:
      break
    case .preparing, .activating, .active, .stopping:
      return
    }

    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    kioskController.injectedFailure = nil
    isTerminationBlocked = true
    endRequest = nil
    environment.prepareSession(BabyWorksConfigurationStore().load())

    kioskTask = Task { [weak self] in
      guard let self else { return }
      let state = await self.kioskController.activate()
      if state.phase == .stopping {
        let request = self.endRequest ?? .adultExit(state.lastExitKind ?? .passphrase)
        self.completeExit(request)
        return
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
        self.presentActivationFailure?(error)
      }
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
