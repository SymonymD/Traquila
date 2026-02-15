import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\PourEntry.date, order: .reverse)]) private var pours: [PourEntry]

    @State private var exportURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.themeMode) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                }

                Section("Units") {
                    Picker("Volume", selection: $settings.volumeUnit) {
                        ForEach(VolumeUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                }

                Section("Responsible Use") {
                    Toggle("Enable Pacing Timer", isOn: $settings.enablePacing)
                    Toggle("Hydration Reminder", isOn: $settings.enableHydrationReminder)
                    Text("Pacing Timer helps space pours with a configurable interval.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Hydration Reminder is a gentle local prompt to drink water.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Traquila is a tracker, not medical advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Button("Export My Data") {
                        exportData()
                    }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share Export File", systemImage: "square.and.arrow.up")
                        }
                    }
                    if let exportError {
                        Text(exportError)
                            .foregroundStyle(.red)
                    }

                    Button("Import (Coming Soon)") { }
                        .disabled(true)
                    Text("TODO: Import flow will be added in a future update.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func exportData() {
        do {
            exportURL = try ExportService.makeExport(bottles: bottles, pours: pours)
            exportError = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            exportError = error.localizedDescription
        }
    }
}
