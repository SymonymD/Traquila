import Combine
import SwiftUI
import UIKit

@MainActor
final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard
    @AppStorage("volumeUnit") var volumeUnitRaw: String = VolumeUnit.oz.rawValue
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("responsibleNudgesEnabled") var responsibleNudgesEnabled: Bool = false
    @AppStorage("enablePacing") var enablePacing: Bool = false
    @AppStorage("enableHydrationReminder") var enableHydrationReminder: Bool = false
    @AppStorage("pacingMinutes") var pacingMinutes: Int = 45
    @AppStorage("favoriteBottleTypesRaw") var favoriteBottleTypesRaw: String = ""
    @AppStorage("discoverySourceMode") var discoverySourceModeRaw: String = DiscoverySourceMode.curatedLocal.rawValue

    @Published var themeMode: AppThemeMode {
        didSet {
            guard themeMode != oldValue else { return }
            defaults.set(themeMode.rawValue, forKey: "themeMode")
            applyInterfaceStyle()
        }
    }

    init() {
        if defaults.object(forKey: "themeMode") == nil {
            defaults.set(AppThemeMode.system.rawValue, forKey: "themeMode")
        }
        let raw = defaults.string(forKey: "themeMode") ?? AppThemeMode.system.rawValue
        themeMode = AppThemeMode(rawValue: raw) ?? .system
        applyInterfaceStyle()
    }

    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }
        set {
            objectWillChange.send()
            volumeUnitRaw = newValue.rawValue
        }
    }

    var favoriteTypes: [BottleType] {
        get {
            favoriteBottleTypesRaw
                .split(separator: ",")
                .compactMap { BottleType(rawValue: String($0)) }
        }
        set {
            favoriteBottleTypesRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var discoverySourceMode: DiscoverySourceMode {
        get { DiscoverySourceMode(rawValue: discoverySourceModeRaw) ?? .curatedLocal }
        set {
            objectWillChange.send()
            discoverySourceModeRaw = newValue.rawValue
        }
    }

    var userPreferences: UserPreferences {
        UserPreferences(
            units: .from(volumeUnit),
            theme: .from(themeMode),
            responsibleNudgesEnabled: responsibleNudgesEnabled,
            pacingTimerEnabled: enablePacing,
            hydrationReminderEnabled: enableHydrationReminder,
            favoriteTypes: favoriteTypes
        )
    }

    func markOnboardingComplete() {
        onboardingComplete = true
    }

    func resetOnboarding() {
        onboardingComplete = false
        favoriteTypes = []
    }

    private func applyInterfaceStyle() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }

        let style: UIUserInterfaceStyle
        switch themeMode {
        case .system:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}
