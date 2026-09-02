import BabyWorkDiagnosticsKit
import SwiftUI

@main
struct BabyWorkDiagnosticsApp: App {
  @State private var report = DiagnosticReport(snapshot: SystemSnapshotCollector.capture())

  var body: some Scene {
    WindowGroup("Diagnostic BabyWork") {
      DiagnosticView(report: report) {
        report = DiagnosticReport(snapshot: SystemSnapshotCollector.capture())
      }
    }
    .defaultSize(width: 760, height: 680)
  }
}

private struct DiagnosticView: View {
  let report: DiagnosticReport
  let refresh: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        ForEach(report.sections.indices, id: \.self) { sectionIndex in
          let section = report.sections[sectionIndex]
          DiagnosticSectionView(section: section)
        }
      }
      .padding(28)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      Button("Actualiser", systemImage: "arrow.clockwise", action: refresh)
        .help("Relire les informations système et les permissions")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Diagnostic de faisabilité")
        .font(.largeTitle.bold())
      Text("Inventaire local en lecture seule pour préparer les essais de confinement macOS.")
        .font(.title3)
        .foregroundStyle(.secondary)
      Text("Aucune frappe n’est capturée, enregistrée ou transmise par cet outil.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }
}

private struct DiagnosticSectionView: View {
  let section: DiagnosticSection

  var body: some View {
    GroupBox {
      Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
        ForEach(section.rows.indices, id: \.self) { rowIndex in
          let row = section.rows[rowIndex]
          GridRow {
            Label {
              Text(row.label)
                .fontWeight(.medium)
            } icon: {
              Image(systemName: row.state.symbolName)
                .foregroundStyle(row.state.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.value)
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .padding(4)
    } label: {
      Text(section.title)
        .font(.headline)
    }
  }
}

extension DiagnosticRowState {
  fileprivate var symbolName: String {
    switch self {
    case .neutral:
      "info.circle"
    case .granted:
      "checkmark.circle.fill"
    case .attention:
      "exclamationmark.triangle.fill"
    }
  }

  fileprivate var color: Color {
    switch self {
    case .neutral:
      .secondary
    case .granted:
      .green
    case .attention:
      .orange
    }
  }
}
