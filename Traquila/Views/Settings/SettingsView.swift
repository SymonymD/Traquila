import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\PourEntry.date, order: .reverse)]) private var pours: [PourEntry]
    @Query(sort: [SortDescriptor(\UserProfile.createdAt, order: .reverse)]) private var profiles: [UserProfile]

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showResetConfirm = false
    @State private var showProfileEditor = false
    @State private var feedbackStatusMessage: String?

    private let feedbackEmailAddress = "hello@traquila.app"

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    if let profile = profiles.first {
                        LabeledContent("Display Name", value: profile.displayName)
                        LabeledContent("Experience Level", value: profile.experienceLevel.rawValue)
                    } else {
                        Text("No profile yet.")
                            .foregroundStyle(.secondary)
                    }

                    Button("Edit Profile") {
                        showProfileEditor = true
                    }
                }

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

                Section("Feedback") {
                    Button {
                        sendFeedbackEmail()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    Button {
                        copyFeedbackTemplate()
                    } label: {
                        Label("Copy Feedback Template", systemImage: "doc.on.doc")
                    }

                    if let feedbackStatusMessage {
                        Text(feedbackStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Feedback emails are sent to \(feedbackEmailAddress).")
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
                    Text("This will show onboarding again on next launch. You can keep or clear your profile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showProfileEditor) {
                NavigationStack {
                    UserProfileEditorView(profile: profiles.first)
                }
            }
            .alert("Reset Onboarding?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Reset (Keep Profile)", role: .destructive) {
                    settings.resetOnboarding()
                }
                Button("Reset & Clear Profile", role: .destructive) {
                    settings.resetOnboarding()
                    clearProfile()
                }
            } message: {
                Text("Choose whether to keep your profile data.")
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

    private func clearProfile() {
        for profile in profiles {
            modelContext.delete(profile)
        }
        try? modelContext.save()
    }

    private func sendFeedbackEmail() {
        let subject = "Traquila Feedback"
        let body = feedbackTemplateBody()
        let recipient = feedbackEmailAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? feedbackEmailAddress
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body

        guard let url = URL(string: "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            feedbackStatusMessage = "Couldn't prepare email."
            return
        }

        openURL(url)
    }

    private func copyFeedbackTemplate() {
        UIPasteboard.general.string = feedbackTemplateBody()
        feedbackStatusMessage = "Feedback template copied."
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func feedbackTemplateBody() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let profileName = profiles.first?.displayName ?? "No profile"

        return """
        What happened?

        What did you expect?

        Steps to reproduce:
        1.
        2.
        3.

        ---
        App version: \(appVersion) (\(build))
        Profile: \(profileName)
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
    }
}

private struct UserProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile?

    @State private var displayName: String
    @State private var experienceLevel: ExperienceLevel
    @State private var selectedStyles: Set<BottleType>
    @State private var selectedContexts: Set<EnjoymentContextOption>
    @State private var cabinetIntent: CabinetIntent?
    @State private var errorText: String?

    init(profile: UserProfile?) {
        self.profile = profile
        _displayName = State(initialValue: profile?.displayName ?? "")
        _experienceLevel = State(initialValue: profile?.experienceLevel ?? .curious)
        _selectedStyles = State(initialValue: Set(profile?.preferredStyles ?? []))
        _selectedContexts = State(initialValue: Set(profile?.preferredContexts ?? []))
        _cabinetIntent = State(initialValue: profile?.cabinetIntent)
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("What should we call you?", text: $displayName)
                Picker("Experience Level", selection: $experienceLevel) {
                    ForEach(ExperienceLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Preferred Styles") {
                ForEach(BottleType.allCases) { type in
                    Toggle(
                        type.rawValue,
                        isOn: Binding(
                            get: { selectedStyles.contains(type) },
                            set: { isOn in
                                if isOn { selectedStyles.insert(type) } else { selectedStyles.remove(type) }
                            }
                        )
                    )
                }
            }

            Section("Typical Contexts") {
                ForEach(EnjoymentContextOption.allCases) { context in
                    Toggle(
                        context.rawValue,
                        isOn: Binding(
                            get: { selectedContexts.contains(context) },
                            set: { isOn in
                                if isOn { selectedContexts.insert(context) } else { selectedContexts.remove(context) }
                            }
                        )
                    )
                }
            }

            Section("Cabinet Intent") {
                Picker("Intent", selection: $cabinetIntent) {
                    Text("None").tag(nil as CabinetIntent?)
                    ForEach(CabinetIntent.allCases) { intent in
                        Text(intent.rawValue).tag(Optional(intent))
                    }
                }
            }

            if let errorText {
                Section {
                    Text(errorText).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
    }

    private func save() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorText = "Display name is required."
            return
        }

        if let profile {
            profile.displayName = trimmed
            profile.experienceLevel = experienceLevel
            profile.preferredStyles = Array(selectedStyles).sorted { $0.rawValue < $1.rawValue }
            profile.preferredContexts = Array(selectedContexts).sorted { $0.rawValue < $1.rawValue }
            profile.cabinetIntent = cabinetIntent
            profile.updatedAt = .now
        } else {
            let newProfile = UserProfile(
                displayName: trimmed,
                experienceLevelRaw: experienceLevel.rawValue,
                preferredStylesRaw: Array(selectedStyles).sorted { $0.rawValue < $1.rawValue }.map(\.rawValue),
                preferredContextsRaw: Array(selectedContexts).sorted { $0.rawValue < $1.rawValue }.map(\.rawValue),
                cabinetIntentRaw: cabinetIntent?.rawValue
            )
            modelContext.insert(newProfile)
        }

        try? modelContext.save()
        dismiss()
    }
}
