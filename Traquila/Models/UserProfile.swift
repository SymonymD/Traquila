import Foundation
import SwiftData

enum ExperienceLevel: String, CaseIterable, Identifiable, Codable {
    case curious = "Curious"
    case enthusiast = "Enthusiast"
    case aficionado = "Aficionado"

    var id: String { rawValue }

    var helperText: String {
        switch self {
        case .curious:
            "You are exploring tequila and building your foundation."
        case .enthusiast:
            "You enjoy discovering expressions and comparing notes."
        case .aficionado:
            "You are refining palate details and curating standout bottles."
        }
    }
}

enum EnjoymentContextOption: String, CaseIterable, Identifiable, Codable {
    case neat = "Neat"
    case onTheRocks = "On the Rocks"
    case cocktails = "Cocktails"
    case flights = "Flights"
    case restaurants = "Restaurants"

    var id: String { rawValue }
}

enum CabinetIntent: String, CaseIterable, Identifiable, Codable {
    case collection = "Building a Collection"
    case tastings = "Tracking Tastings"
    case finds = "Remembering Great Finds"
    case palate = "Refining My Palate"

    var id: String { rawValue }
}

@Model
final class UserProfile {
    var displayName: String
    var experienceLevelRaw: String
    var preferredStylesRaw: [String]
    var preferredContextsRaw: [String]
    var cabinetIntentRaw: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        displayName: String,
        experienceLevelRaw: String,
        preferredStylesRaw: [String] = [],
        preferredContextsRaw: [String] = [],
        cabinetIntentRaw: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.displayName = displayName
        self.experienceLevelRaw = experienceLevelRaw
        self.preferredStylesRaw = preferredStylesRaw
        self.preferredContextsRaw = preferredContextsRaw
        self.cabinetIntentRaw = cabinetIntentRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var experienceLevel: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .curious }
        set { experienceLevelRaw = newValue.rawValue }
    }

    var preferredStyles: [BottleType] {
        get { preferredStylesRaw.compactMap(BottleType.init(rawValue:)) }
        set { preferredStylesRaw = newValue.map(\.rawValue) }
    }

    var preferredContexts: [EnjoymentContextOption] {
        get { preferredContextsRaw.compactMap(EnjoymentContextOption.init(rawValue:)) }
        set { preferredContextsRaw = newValue.map(\.rawValue) }
    }

    var cabinetIntent: CabinetIntent? {
        get { cabinetIntentRaw.flatMap(CabinetIntent.init(rawValue:)) }
        set { cabinetIntentRaw = newValue?.rawValue }
    }
}
