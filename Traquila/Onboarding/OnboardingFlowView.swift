import SwiftData
import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case howItWorks
    case createProfile
}

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @State private var step: OnboardingStep = .welcome
    @State private var displayName = ""
    @State private var experienceLevel: ExperienceLevel?
    @State private var preferredStyles: Set<BottleType> = []
    @State private var preferredContexts: Set<EnjoymentContextOption> = []
    @State private var cabinetIntent: CabinetIntent?

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
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .animation(.easeInOut(duration: 0.28), value: step)
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
                advanceTo(.createProfile)
            }
        case .createProfile:
            CreateProfileStep(
                displayName: $displayName,
                experienceLevel: $experienceLevel,
                preferredStyles: $preferredStyles,
                preferredContexts: $preferredContexts,
                cabinetIntent: $cabinetIntent
            ) {
                finishOnboarding()
            } onSkip: {
                if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    displayName = "Amigo"
                }
                if experienceLevel == nil {
                    experienceLevel = .curious
                }
                finishOnboarding()
            }
        }
    }

    private func advanceTo(_ next: OnboardingStep) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation {
            step = next
        }
    }

    private func finishOnboarding() {
        persistProfile()
        settings.markOnboardingComplete()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func persistProfile() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "Amigo" : trimmedName
        let finalLevel = experienceLevel ?? .curious

        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.displayName = finalName
            existing.experienceLevel = finalLevel
            existing.preferredStyles = Array(preferredStyles).sorted { $0.rawValue < $1.rawValue }
            existing.preferredContexts = Array(preferredContexts).sorted { $0.rawValue < $1.rawValue }
            existing.cabinetIntent = cabinetIntent
            existing.updatedAt = .now
        } else {
            let profile = UserProfile(
                displayName: finalName,
                experienceLevelRaw: finalLevel.rawValue,
                preferredStylesRaw: Array(preferredStyles).sorted { $0.rawValue < $1.rawValue }.map(\.rawValue),
                preferredContextsRaw: Array(preferredContexts).sorted { $0.rawValue < $1.rawValue }.map(\.rawValue),
                cabinetIntentRaw: cabinetIntent?.rawValue
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
    }
}

private struct WelcomeStep: View {
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            TraquilaLogoView(inkColor: .white)
                .accessibilityAddTraits(.isHeader)
            Text("Your digital tequila cabinet and tasting journal.")
                .font(TraquilaTheme.headingFont())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.95))
            Text("Track bottles, capture memorable experiences, and build your personal taste map.")
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
    @State private var animatePanel = false
    @State private var isUserInteracting = false

    private let autoAdvanceTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

    private let panels: [(icon: String, title: String, body: String)] = [
        ("archivebox", "Curate your cabinet", "Save bottles with expression, region, notes, and photos."),
        ("square.and.pencil", "Capture each tasting", "Log where and how you enjoyed it with a quick rating."),
        ("chart.line.uptrend.xyaxis", "Learn your preferences", "See top bottles, favorite styles, and standout experiences.")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("How It Works")
                .font(TraquilaTheme.titleFont())
                .foregroundStyle(.white)
            Text("Traquila helps you remember what you loved and discover what to reach for next.")
                .font(TraquilaTheme.bodyFont())
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, panel in
                    HowItWorksPanel(
                        icon: panel.icon,
                        title: panel.title,
                        detail: panel.body,
                        isActive: page == idx,
                        animatePanel: animatePanel
                    )
                    .tag(idx)
                    .padding(.top, 20)
                    .transition(.opacity.combined(with: .slide))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 320)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isUserInteracting = true
                    }
                    .onEnded { _ in
                        isUserInteracting = false
                    }
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    animatePanel = true
                }
            }
            .onChange(of: page) { _, _ in
                animatePanel = false
                withAnimation(.easeOut(duration: 0.45)) {
                    animatePanel = true
                }
            }
            .onReceive(autoAdvanceTimer) { _ in
                guard !isUserInteracting else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    page = (page + 1) % panels.count
                }
            }

            Button("Continue", action: onContinue)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Continue onboarding")
        }
    }
}

private struct HowItWorksPanel: View {
    let icon: String
    let title: String
    let detail: String
    let isActive: Bool
    let animatePanel: Bool

    @State private var floatIcon = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TraquilaTheme.marigold.opacity(0.18))
                    .frame(width: 90, height: 90)
                    .scaleEffect(isActive ? 1.0 : 0.94)
                    .opacity(isActive ? 1.0 : 0.7)

                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(TraquilaTheme.marigold)
                    .offset(y: (isActive && floatIcon) ? -3 : 2)
                    .scaleEffect(isActive ? 1.0 : 0.96)
            }
            .padding(.bottom, 4)

            Text(title)
                .font(TraquilaTheme.headingFont())
                .foregroundStyle(.white)
                .opacity(animatePanel ? 1 : 0)
                .offset(y: animatePanel ? 0 : 8)
                .animation(.easeOut(duration: 0.28).delay(0.05), value: animatePanel)

            Text(detail)
                .font(TraquilaTheme.bodyFont())
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(animatePanel ? 1 : 0)
                .offset(y: animatePanel ? 0 : 10)
                .animation(.easeOut(duration: 0.32).delay(0.12), value: animatePanel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        )
        .opacity(animatePanel ? 1 : 0.85)
        .offset(y: animatePanel ? 0 : 10)
        .animation(.easeOut(duration: 0.4), value: animatePanel)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                floatIcon = true
            }
        }
    }
}

private struct CreateProfileStep: View {
    @Binding var displayName: String
    @Binding var experienceLevel: ExperienceLevel?
    @Binding var preferredStyles: Set<BottleType>
    @Binding var preferredContexts: Set<EnjoymentContextOption>
    @Binding var cabinetIntent: CabinetIntent?

    let onContinue: () -> Void
    let onSkip: () -> Void

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && experienceLevel != nil
    }

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create Your Profile")
                        .font(TraquilaTheme.titleFont())
                        .foregroundStyle(.white)

                    TextField("What should we call you?", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .foregroundColor(.black)
                        .tint(Color(red: 0.30, green: 0.20, blue: 0.16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        .environment(\.colorScheme, .light)
                        .accessibilityLabel("Display name")

                    if !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("\(displayName.trimmingCharacters(in: .whitespacesAndNewlines))'s Cabinet")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Experience Level")
                            .font(TraquilaTheme.headingFont())
                            .foregroundStyle(.white)
                        ForEach(ExperienceLevel.allCases) { level in
                            Button {
                                experienceLevel = level
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: experienceLevel == level ? "checkmark.circle.fill" : "circle")
                                        Text(level.rawValue)
                                            .font(.headline)
                                    }
                                    Text(level.helperText)
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.30, green: 0.27, blue: 0.24))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(experienceLevel == level ? 0.92 : 0.80))
                                )
                                .foregroundStyle(Color(red: 0.14, green: 0.12, blue: 0.11))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(level.rawValue)
                        }
                    }

                    Text("Preferred Styles (optional)")
                        .font(TraquilaTheme.headingFont())
                        .foregroundStyle(.white)
                    MultiSelectChipGroup(
                        items: BottleType.allCases,
                        selected: $preferredStyles,
                        label: { $0.rawValue }
                    )

                    Text("Typical Enjoyment Context (optional)")
                        .font(TraquilaTheme.headingFont())
                        .foregroundStyle(.white)
                    MultiSelectChipGroup(
                        items: EnjoymentContextOption.allCases,
                        selected: $preferredContexts,
                        label: { $0.rawValue }
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cabinet Intent (optional)")
                            .font(TraquilaTheme.headingFont())
                            .foregroundStyle(.white)
                        Picker("Cabinet Intent", selection: $cabinetIntent) {
                            Text("None").tag(nil as CabinetIntent?)
                            ForEach(CabinetIntent.allCases) { intent in
                                Text(intent.rawValue).tag(Optional(intent))
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(Color(red: 0.14, green: 0.12, blue: 0.11))
                        .tint(Color(red: 0.30, green: 0.20, blue: 0.16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            VStack(spacing: 10) {
                Button("Continue") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.65)
                .accessibilityLabel("Continue")

                HStack {
                    Spacer()
                    Button("Skip for now") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSkip()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.95))
                    .accessibilityLabel("Skip for now")
                    Spacer()
                }
            }
            .padding(.bottom, 6)
        }
    }
}

private struct MultiSelectChipGroup<Item: Hashable & Identifiable>: View {
    let items: [Item]
    @Binding var selected: Set<Item>
    let label: (Item) -> String

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                Button {
                    if selected.contains(item) {
                        selected.remove(item)
                    } else {
                        selected.insert(item)
                    }
                } label: {
                    Text(label(item))
                        .font(.subheadline)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selected.contains(item) ? TraquilaTheme.marigold.opacity(0.9) : Color.white.opacity(0.16))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundStyle(selected.contains(item) ? TraquilaTheme.charcoal : .white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(item))
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
            .foregroundStyle(Color(red: 0.14, green: 0.12, blue: 0.11))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(configuration.isPressed ? 0.78 : 0.92), in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
