import Foundation

enum BottleType: String, CaseIterable, Identifiable, Codable {
    case blanco = "Blanco"
    case reposado = "Reposado"
    case anejo = "Añejo"
    case extraAnejo = "Extra Añejo"
    case cristalino = "Cristalino"
    case mezcal = "Mezcal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .blanco: "sun.max"
        case .reposado: "clock"
        case .anejo: "hourglass"
        case .extraAnejo: "crown"
        case .cristalino: "sparkles"
        case .mezcal: "flame"
        }
    }
}

enum Region: String, CaseIterable, Identifiable, Codable {
    case highlands = "Highlands"
    case lowlands = "Lowlands"
    case otherUnknown = "Other/Unknown"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .highlands: "mountain.2"
        case .lowlands: "leaf"
        case .otherUnknown: "questionmark.circle"
        }
    }
}

enum ServeStyle: String, CaseIterable, Identifiable, Codable {
    case neat = "Neat"
    case onTheRocks = "On the rocks"
    case margarita = "Margarita"
    case paloma = "Paloma"
    case ranchWater = "Ranch Water"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .neat: "drop"
        case .onTheRocks: "snow"
        case .margarita: "sun.haze"
        case .paloma: "bird"
        case .ranchWater: "water.waves"
        case .other: "ellipsis.circle"
        }
    }
}

enum PourContext: String, CaseIterable, Identifiable, Codable {
    case atHome = "At Home"
    case bar = "Bar"
    case restaurant = "Restaurant"
    case party = "Party"
    case tasting = "Tasting"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .atHome: "house"
        case .bar: "wineglass"
        case .restaurant: "fork.knife"
        case .party: "party.popper"
        case .tasting: "list.bullet.clipboard"
        }
    }
}

enum PourAmountPreset: String, CaseIterable, Identifiable {
    case half = "0.5 oz"
    case one = "1 oz"
    case oneHalf = "1.5 oz"
    case two = "2 oz"
    case custom = "Custom"

    var id: String { rawValue }

    var value: Double? {
        switch self {
        case .half: 0.5
        case .one: 1
        case .oneHalf: 1.5
        case .two: 2
        case .custom: nil
        }
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
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
}

enum VolumeUnit: String, CaseIterable, Identifiable {
    case oz
    case ml

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oz: "Ounces (oz)"
        case .ml: "Milliliters (ml)"
        }
    }
}
