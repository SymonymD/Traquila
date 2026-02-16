import Foundation

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case ounces
    case milliliters

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ounces: "Ounces (oz)"
        case .milliliters: "Milliliters (ml)"
        }
    }

    var volumeUnit: VolumeUnit {
        switch self {
        case .ounces: .oz
        case .milliliters: .ml
        }
    }

    static func from(_ unit: VolumeUnit) -> MeasurementUnit {
        switch unit {
        case .oz: .ounces
        case .ml: .milliliters
        }
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var mode: AppThemeMode {
        switch self {
        case .system: .system
        case .light: .light
        case .dark: .dark
        }
    }

    static func from(_ mode: AppThemeMode) -> AppTheme {
        switch mode {
        case .system: .system
        case .light: .light
        case .dark: .dark
        }
    }
}

struct UserPreferences: Codable {
    var units: MeasurementUnit
    var theme: AppTheme
    var responsibleNudgesEnabled: Bool
    var pacingTimerEnabled: Bool
    var hydrationReminderEnabled: Bool
    var favoriteTypes: [BottleType]

    static let `default` = UserPreferences(
        units: .ounces,
        theme: .system,
        responsibleNudgesEnabled: false,
        pacingTimerEnabled: false,
        hydrationReminderEnabled: false,
        favoriteTypes: []
    )
}
