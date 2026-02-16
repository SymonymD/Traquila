import Foundation

@MainActor
enum SettingsCoordinator {
    static func apply(_ preferences: UserPreferences, to settings: AppSettings) {
        let effectivePacing = preferences.responsibleNudgesEnabled ? preferences.pacingTimerEnabled : false
        let effectiveHydration = preferences.responsibleNudgesEnabled ? preferences.hydrationReminderEnabled : false
        settings.volumeUnit = preferences.units.volumeUnit
        settings.themeMode = preferences.theme.mode
        settings.responsibleNudgesEnabled = preferences.responsibleNudgesEnabled
        settings.enablePacing = effectivePacing
        settings.enableHydrationReminder = effectiveHydration
        settings.favoriteTypes = preferences.favoriteTypes
    }
}
