import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\PourEntry.date, order: .reverse)]) private var pours: [PourEntry]

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showResetConfirm = false

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

                Section("Discovery Data") {
                    Picker("Source", selection: $settings.discoverySourceMode) {
                        ForEach(DiscoverySourceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Text(settings.discoverySourceMode.helperText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Tip: Start with Curated Local to keep costs low while validating demand.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Responsible Use") {
                    Toggle("Enable Responsible Nudges", isOn: $settings.responsibleNudgesEnabled.animation())
                    if settings.responsibleNudgesEnabled {
                        Toggle("Enable Pacing Timer", isOn: $settings.enablePacing)
                        Toggle("Hydration Reminder", isOn: $settings.enableHydrationReminder)
                    }
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

                Section("Onboarding") {
                    Button("Reset Onboarding", role: .destructive) {
                        showResetConfirm = true
                    }
                    Text("This will show onboarding again on next launch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Onboarding?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetOnboarding()
                }
            } message: {
                Text("Your onboarding flow will return the next time the app launches.")
            }
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
