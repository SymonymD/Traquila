import Combine
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("themeMode") var themeModeRaw: String = AppThemeMode.system.rawValue
    @AppStorage("volumeUnit") var volumeUnitRaw: String = VolumeUnit.oz.rawValue
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("responsibleNudgesEnabled") var responsibleNudgesEnabled: Bool = false
    @AppStorage("enablePacing") var enablePacing: Bool = false
    @AppStorage("enableHydrationReminder") var enableHydrationReminder: Bool = false
    @AppStorage("pacingMinutes") var pacingMinutes: Int = 45
    @AppStorage("favoriteBottleTypesRaw") var favoriteBottleTypesRaw: String = ""
    @AppStorage("discoverySourceMode") var discoverySourceModeRaw: String = DiscoverySourceMode.curatedLocal.rawValue

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }

    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }
        set { volumeUnitRaw = newValue.rawValue }
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
        set { discoverySourceModeRaw = newValue.rawValue }
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
}
