import BabyWorkDiagnosticsKit
import SwiftUI

@main
struct BabyWorkDiagnosticsApp: App {
  @StateObject private var model = DiagnosticsSessionModel()

  var body: some Scene {
    WindowGroup("Diagnostic BabyWork") {
      DiagnosticView(model: model)
    }
    .defaultSize(width: 780, height: 860)
  }
}

private struct DiagnosticView: View {
  @ObservedObject var model: DiagnosticsSessionModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        ForEach(model.report.sections.indices, id: \.self) { sectionIndex in
          let section = model.report.sections[sectionIndex]
          DiagnosticSectionView(section: section)
        }

        InputFilterPanel(model: model)
      }
      .padding(28)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      Button("Actualiser", systemImage: "arrow.clockwise") {
        model.refresh()
      }
      .help("Relire les informations système et les permissions")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Diagnostic de faisabilité")
        .font(.largeTitle.bold())
      Text("Inventaire local et prototype de filtrage d’entrée pour la phase 0.")
        .font(.title3)
        .foregroundStyle(.secondary)
      Text("Les frappes ne sont jamais journalisées ni persistées. Seuls des compteurs de raccourcis absorbés sont affichés.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }
}

private struct InputFilterPanel: View {
  @ObservedObject var model: DiagnosticsSessionModel

  var body: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 16) {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
          GridRow {
            Text("État du filtre")
              .fontWeight(.medium)
            Text(model.filterStatus.displayName)
              .textSelection(.enabled)
          }
          GridRow {
            Text("Sandbox App")
              .fontWeight(.medium)
            Text(sandboxLabel)
              .textSelection(.enabled)
          }
        }

        HStack(spacing: 12) {
          Button(model.isFilterActive ? "Désactiver le filtre" : "Activer le filtre") {
            model.toggleFilter()
          }
          .keyboardShortcut(.defaultAction)

          Button("Demander Surveillance de l’entrée") {
            model.requestInputMonitoringPrompt()
          }

          Button("Demander Accessibilité") {
            model.requestAccessibilityPrompt()
          }

          if case .disabledByTimeout = model.filterStatus {
            Button("Réactiver le tap") {
              model.reenableFilter()
            }
          }
          if case .disabledByUserInput = model.filterStatus {
            Button("Réactiver le tap") {
              model.reenableFilter()
            }
          }
        }

        Text("Pendant que le filtre est actif, tester les raccourcis ci-dessous. Le compteur augmente uniquement pour les absorptions détectées — jamais le caractère saisi.")
          .font(.callout)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(MonitoredShortcut.allCases, id: \.self) { shortcut in
            HStack {
              Text(shortcut.displayName)
              Spacer()
              Text("\(model.count(for: shortcut))")
                .monospacedDigit()
                .foregroundStyle(model.count(for: shortcut) > 0 ? Color.green : Color.secondary)
            }
          }
        }
      }
      .padding(4)
    } label: {
      Text("Filtrage actif (CGEventTap de session)")
        .font(.headline)
    }
  }

  private var sandboxLabel: String {
    if let label = Bundle.main.object(forInfoDictionaryKey: "BabyWorkSandboxMode") as? String,
      !label.isEmpty
    {
      return label
    }
    if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
      return "Conteneur détecté à l’exécution"
    }
    return "Non détecté à l’exécution"
  }
}

private struct DiagnosticSectionView: View {
  let section: DiagnosticSection

  var body: some View {
    GroupBox {
      Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
        ForEach(section.rows.indices, id: \.self) { rowIndex in
          let row = section.rows[rowIndex]
          let presentation = row.state.presentation
          GridRow {
            Label {
              Text(row.label)
                .fontWeight(.medium)
            } icon: {
              Image(systemName: presentation.symbolName)
                .foregroundStyle(presentation.color)
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
  fileprivate var presentation: (symbolName: String, color: Color) {
    switch self {
    case .neutral:
      ("info.circle", .secondary)
    case .granted:
      ("checkmark.circle.fill", .green)
    case .attention:
      ("exclamationmark.triangle.fill", .orange)
    }
  }
}
