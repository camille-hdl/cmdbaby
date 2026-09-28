import AppKit
import ApplicationServices
import BabyWorkDiagnosticsKit
import Carbon
import Combine
import CoreGraphics
import Foundation
import IOKit.hid

/// État affiché par SwiftUI. Intentionnellement hors `@MainActor` : le body SwiftUI
/// est parfois évalué depuis un observateur AppKit, ce qui crashait l’accès à un
/// `ObservableObject` isolé MainActor (`swift_task_isCurrentExecutor`).
final class DiagnosticsPublishedState: ObservableObject, @unchecked Sendable {
  @Published var report: DiagnosticReport
  @Published var filterStatus: InputFilterStatus = .inactive
  @Published var suppressedCounts: [MonitoredShortcut: Int] = [:]
  @Published var kioskState = KioskSessionState()
  @Published var injectedFailureChoice: FailureInjectionChoice = .none

  init(report: DiagnosticReport) {
    self.report = report
  }

  var isFilterActive: Bool { filterStatus.isRunning }
  var isKioskActive: Bool { kioskState.blocksTermination }

  func count(for shortcut: MonitoredShortcut) -> Int {
    suppressedCounts[shortcut, default: 0]
  }
}

@MainActor
final class DiagnosticsSessionModel {
  let ui: DiagnosticsPublishedState
  private let environment: AppKitKioskEnvironment
  private let kioskController: KioskSessionController
  private weak var terminationDelegate: BabyWorksAppDelegate?
  private var kioskTask: Task<Void, Never>?

  init(terminationGate: TerminationGate = TerminationGate()) {
    let environment = AppKitKioskEnvironment(terminationGate: terminationGate)
    self.environment = environment
    kioskController = KioskSessionController(services: environment)
    ui = DiagnosticsPublishedState(report: DiagnosticReport(snapshot: SystemSnapshotCollector.capture()))
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
          guard let self else { return }
          self.ui.filterStatus = status
          if !self.ui.kioskState.blocksTermination {
            self.refresh()
          }
        }
      }
    }
    environment.onCountsChange = { [weak self] counts in
      DispatchQueue.main.async {
        MainActor.assumeIsolated {
          self?.ui.suppressedCounts = counts
        }
      }
    }

    let stopFlag = kioskController.externalStop
    let gate = environment.terminationGate
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

  func attachDiagnosticWindow(hide: @escaping () -> Void, reveal: @escaping () -> Void) {
    environment.onHideDiagnosticInterface = hide
    environment.onRevealDiagnosticInterface = reveal
  }

  func attachRevealPump(_ pump: DiagnosticRevealPump) {
    environment.emergency.reveal = {
      pump.request()
    }
  }

  func refresh() {
    ui.report = DiagnosticReport(snapshot: SystemSnapshotCollector.capture())
  }

  func requestInputMonitoringPrompt() {
    _ = CGRequestListenEventAccess()
    _ = CGRequestPostEventAccess()
    _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    openPrivacyPane(suffix: "Privacy_ListenEvent")
    refresh()
  }

  func requestAccessibilityPrompt() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    openPrivacyPane(suffix: "Privacy_Accessibility")
    refresh()
  }

  func revealAppInFinder() {
    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
  }

  private func openPrivacyPane(suffix: String) {
    let candidates = [
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(suffix)",
      "x-apple.systempreferences:com.apple.preference.security?\(suffix)",
    ]
    for candidate in candidates {
      if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
        return
      }
    }
  }

  func toggleFilter() {
    if ui.isFilterActive {
      stopFilter()
    } else {
      startFilter()
    }
  }

  func startFilter() {
    guard !ui.isKioskActive else { return }
    ui.suppressedCounts = [:]
    ui.filterStatus = .starting
    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    Task {
      do {
        try await environment.startInputFilter()
      } catch {
        ui.filterStatus = .failed(error.localizedDescription)
        refresh()
      }
    }
  }

  func stopFilter() {
    environment.stopInputFilter()
    ui.filterStatus = .inactive
  }

  func reenableFilter() {
    environment.reenableFilter()
  }

  func setInjectedFailure(_ choice: FailureInjectionChoice) {
    ui.injectedFailureChoice = choice
  }

  func startKiosk(injected: FailureInjectionChoice) {
    guard kioskTask == nil else { return }
    switch ui.kioskState.phase {
    case .configuration, .failed:
      break
    case .preparing, .activating, .active, .stopping:
      return
    }

    ui.injectedFailureChoice = injected
    KeyboardLayoutLetter.shared.refreshFromCurrentLayout()
    ui.suppressedCounts = [:]
    kioskController.injectedFailure = injected.step
    environment.terminationGate.setBlocked(true)
    environment.emergency.arm()

    kioskTask = Task { [weak self] in
      guard let self else { return }
      let state = await self.kioskController.activate()
      self.ui.kioskState = state
      self.kioskTask = nil
      if state.phase != .active {
        self.environment.terminationGate.setBlocked(false)
        self.ui.filterStatus = .inactive
        self.environment.revealDiagnosticInterface()
      }
      if state.phase == .failed || state.phase == .configuration {
        self.refresh()
      }
    }
  }

  func quit() {
    environment.emergency.quit()
  }

  func handleAdultExit(_ kind: AdultExitKind) {
    switch kioskController.state.phase {
    case .preparing, .activating, .active, .stopping:
      ui.kioskState = kioskController.deactivate(exitKind: kind)
      ui.filterStatus = .inactive
      environment.terminationGate.setBlocked(false)
      refresh()
      environment.revealDiagnosticInterface()
    case .configuration, .failed:
      stopFilter()
    }
  }

  func relaunch() {
    let path = Bundle.main.bundlePath
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "sleep 0.6; /usr/bin/open \"\(path)\""]
    try? task.run()
    NSApp.terminate(nil)
  }
}
