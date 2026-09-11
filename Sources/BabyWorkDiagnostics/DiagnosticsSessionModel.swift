import ApplicationServices
import BabyWorkDiagnosticsKit
import CoreGraphics
import Foundation

@MainActor
final class DiagnosticsSessionModel: ObservableObject {
  @Published private(set) var report: DiagnosticReport
  @Published private(set) var filterStatus: InputFilterStatus = .inactive
  @Published private(set) var suppressedCounts: [MonitoredShortcut: Int] = [:]

  private var filter: SessionInputFilter?

  init() {
    report = DiagnosticReport(snapshot: SystemSnapshotCollector.capture())
  }

  var isFilterActive: Bool {
    switch filterStatus {
    case .active, .starting, .disabledByTimeout, .disabledByUserInput:
      true
    case .inactive, .failed:
      false
    }
  }

  func refresh() {
    report = DiagnosticReport(snapshot: SystemSnapshotCollector.capture())
  }

  func requestInputMonitoringPrompt() {
    _ = CGRequestListenEventAccess()
    refresh()
  }

  func requestAccessibilityPrompt() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    refresh()
  }

  func toggleFilter() {
    if isFilterActive {
      stopFilter()
    } else {
      startFilter()
    }
  }

  func startFilter() {
    stopFilter()
    suppressedCounts = [:]
    filterStatus = .starting

    let engine = SessionInputFilter(
      onStatusChange: { [weak self] status in
        Task { @MainActor in
          self?.filterStatus = status
          if case .failed = status {
            self?.filter = nil
          }
          self?.refresh()
        }
      },
      onCountsChange: { [weak self] counts in
        Task { @MainActor in
          self?.suppressedCounts = counts
        }
      }
    )
    filter = engine
    engine.start()
  }

  func stopFilter() {
    filter?.stop()
    filter = nil
    filterStatus = .inactive
  }

  func reenableFilter() {
    filter?.reenableTapIfPossible()
  }

  func count(for shortcut: MonitoredShortcut) -> Int {
    suppressedCounts[shortcut, default: 0]
  }
}
