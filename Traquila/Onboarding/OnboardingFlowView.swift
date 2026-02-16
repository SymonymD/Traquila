import SwiftUI
import UserNotifications

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case howItWorks
    case preferences
    case notifications
    case personalization
}

struct OnboardingFlowView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var step: OnboardingStep = .welcome
    @State private var preferences: UserPreferences
    @State private var requestStatusText: String?
    @State private var askToAddFirstBottle = false
    @State private var showFirstBottleSheet = false
    @State private var hasLoadedInitialPreferences = false

    init() {
        _preferences = State(initialValue: .default)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TraquilaTheme.agaveGreen.opacity(0.96), TraquilaTheme.terracotta.opacity(0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay {
                DecorativeTileOverlay()
                    .opacity(0.12)
                    .ignoresSafeArea()
            }

            content
                .padding()
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.easeInOut(duration: 0.28), value: step)
        }
        .sheet(isPresented: $showFirstBottleSheet) {
            NavigationStack {
                BottleEditView()
            }
        }
        .onAppear {
            guard !hasLoadedInitialPreferences else { return }
            preferences = settings.userPreferences
            hasLoadedInitialPreferences = true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            WelcomeStep {
                advanceTo(.howItWorks)
            }
        case .howItWorks:
            HowItWorksStep {
                advanceTo(.preferences)
            }
        case .preferences:
            PreferencesStep(preferences: $preferences) {
                if shouldShowNotificationsStep {
                    advanceTo(.notifications)
                } else {
                    advanceTo(.personalization)
                }
            }
        case .notifications:
            NotificationsStep(statusText: $requestStatusText) {
                requestNotificationsAndContinue()
            } onSkip: {
                advanceTo(.personalization)
            }
        case .personalization:
            PersonalizationStep(
                selectedTypes: Binding(
                    get: { Set(preferences.favoriteTypes) },
                    set: { preferences.favoriteTypes = Array($0).sorted { $0.rawValue < $1.rawValue } }
                ),
                addFirstBottle: $askToAddFirstBottle
            ) {
                finishOnboarding()
            }
        }
    }

    private var shouldShowNotificationsStep: Bool {
        preferences.responsibleNudgesEnabled && (preferences.hydrationReminderEnabled || preferences.pacingTimerEnabled)
    }

    private func advanceTo(_ next: OnboardingStep) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation {
            step = next
        }
    }

    private func requestNotificationsAndContinue() {
        Task {
            let granted = await NotificationPermissionService.requestPermission()
            await MainActor.run {
                requestStatusText = granted ? "Notifications enabled." : "Notifications remain off. You can change this later in Settings."
                advanceTo(.personalization)
            }
        }
    }

    private func finishOnboarding() {
        SettingsCoordinator.apply(preferences, to: settings)
        settings.markOnboardingComplete()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if askToAddFirstBottle {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showFirstBottleSheet = true
            }
        }
    }
}

private struct WelcomeStep: View {
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            TraquilaLogoView(inkColor: .white)
                .accessibilityAddTraits(.isHeader)
            Text("Track your tequila and mezcal, log each pour, and use insights to enjoy more intentionally.")
                .font(TraquilaTheme.headingFont())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.95))
            Text("A personal tasting and pour tracker for mindful drinking.")
                .font(TraquilaTheme.bodyFont())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.88))
            Spacer()

            Button("Begin", action: onBegin)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Begin onboarding")

            Text("Not medical advice.")
                .font(TraquilaTheme.captionFont())
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct HowItWorksStep: View {
    let onContinue: () -> Void
    @State private var page = 0

    private let panels: [(icon: String, title: String, body: String)] = [
        ("wineglass", "Catalog bottles", "Save what you drink: bottle details, ratings, tasting notes, and photos."),
        ("list.bullet.clipboard", "Log pours", "Record each pour with amount, serve style, and context so your history is clear."),
        ("chart.line.uptrend.xyaxis", "Insights + pacing", "See weekly/monthly trends and use pacing reminders for intentional sessions.")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("How It Works")
                .font(TraquilaTheme.titleFont())
                .foregroundStyle(.white)
            Text("Traquila helps you remember what you liked, how much you poured, and your overall patterns.")
                .font(TraquilaTheme.bodyFont())
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, panel in
                    VStack(spacing: 14) {
                        Image(systemName: panel.icon)
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(TraquilaTheme.marigold)
                            .symbolEffect(.appear)
                        Text(panel.title)
                            .font(TraquilaTheme.headingFont())
                            .foregroundStyle(.white)
                        Text(panel.body)
                            .font(TraquilaTheme.bodyFont())
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .tag(idx)
                    .padding(.top, 20)
                    .transition(.opacity.combined(with: .slide))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 320)

            Button("Continue", action: onContinue)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Continue onboarding")
        }
    }
}

private struct PreferencesStep: View {
    @Binding var preferences: UserPreferences
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Your Preferences")
                    .font(TraquilaTheme.titleFont())
                    .foregroundStyle(.white)

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Units", selection: $preferences.units) {
                            ForEach(MeasurementUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Theme", selection: $preferences.theme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Enable Responsible Nudges", isOn: $preferences.responsibleNudgesEnabled.animation())

                        if preferences.responsibleNudgesEnabled {
                            Toggle("Pacing Timer", isOn: $preferences.pacingTimerEnabled)
                            Toggle("Hydration Reminder", isOn: $preferences.hydrationReminderEnabled)
                        }
                    }
                    .tint(TraquilaTheme.terracotta)
                }
                .groupBoxStyle(OnboardingGroupStyle())

                Button("Continue", action: onContinue)
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                    .accessibilityLabel("Save preferences and continue")
            }
        }
    }
}

private struct NotificationsStep: View {
    @Binding var statusText: String?
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.badge")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(TraquilaTheme.marigold)

            Text("Stay in Rhythm")
                .font(TraquilaTheme.titleFont())
                .foregroundStyle(.white)

            Text("Allow notifications so Traquila can deliver pacing and hydration reminders when you choose to use them.")
                .font(TraquilaTheme.bodyFont())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.95))

            if let statusText {
                Text(statusText)
                    .font(TraquilaTheme.captionFont())
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
            }

            Button("Allow Notifications", action: onAllow)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Allow notifications")
            Button("Skip") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSkip()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.95))
            Spacer()
        }
    }
}

private struct PersonalizationStep: View {
    @State private var availableTypes: [BottleType] = [.blanco, .reposado, .anejo, .mezcal]
    @Binding var selectedTypes: Set<BottleType>
    @Binding var addFirstBottle: Bool
    let onEnter: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Personalize")
                    .font(TraquilaTheme.titleFont())
                    .foregroundStyle(.white)

                Text("What styles do you enjoy most?")
                    .font(TraquilaTheme.headingFont())
                    .foregroundStyle(.white)

                FlexibleChipLayout(items: availableTypes, selected: $selectedTypes)

                Toggle("Add my first bottle now", isOn: $addFirstBottle)
                    .tint(TraquilaTheme.marigold)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Add first bottle after onboarding")

                Button("Enter Traquila") {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    onEnter()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Enter Traquila")
            }
        }
    }
}

private struct FlexibleChipLayout: View {
    let items: [BottleType]
    @Binding var selected: Set<BottleType>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { type in
                Button {
                    if selected.contains(type) {
                        selected.remove(type)
                    } else {
                        selected.insert(type)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: selected.contains(type) ? "checkmark.circle.fill" : "circle")
                        Text(type.rawValue)
                    }
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selected.contains(type) ? TraquilaTheme.marigold.opacity(0.85) : Color.white.opacity(0.14), in: Capsule())
                    .foregroundStyle(selected.contains(type) ? TraquilaTheme.charcoal : .white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.rawValue)
                .accessibilityHint("Double tap to select")
            }
        }
    }
}

private struct DecorativeTileOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let step: CGFloat = 28
                stride(from: 0, through: proxy.size.width, by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }
                stride(from: 0, through: proxy.size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }
            .stroke(.white.opacity(0.06), lineWidth: 0.7)
        }
        .allowsHitTesting(false)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(TraquilaTheme.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(configuration.isPressed ? 0.78 : 0.92), in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

private struct OnboardingGroupStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.content
        }
        .padding(14)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 14))
    }
}

@MainActor
enum NotificationPermissionService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
