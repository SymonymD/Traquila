import Combine
import Foundation

enum ExperienceRatingFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case fourPlus = "4★+"
    case threePlus = "3★+"
    case unrated = "Unrated"

    var id: String { rawValue }
}

enum ExperienceTimeRange: String, CaseIterable, Identifiable {
    case d30 = "30D"
    case d90 = "90D"
    case ytd = "YTD"
    case all = "All"

    var id: String { rawValue }
}

enum ExperienceSortOption: String, CaseIterable, Identifiable {
    case topRated = "Top Rated"
    case mostLogged = "Most Logged"
    case mostRecent = "Most Recent"
    case bestAtRestaurant = "Best At Restaurant"

    var id: String { rawValue }
}

enum TopBottleRankingMetric: String, CaseIterable, Identifiable {
    case avgRating = "Avg Rating"
    case mostLogged = "Most Logged"
    case recency = "Recency"

    var id: String { rawValue }
}

enum ExperiencePlace: String, CaseIterable, Identifiable {
    case home = "Home"
    case bar = "Bar"
    case restaurant = "Restaurant"
    case event = "Event"
    case tasting = "Tasting"

    var id: String { rawValue }

    static func from(context: PourContext) -> ExperiencePlace {
        switch context {
        case .atHome: return .home
        case .bar: return .bar
        case .restaurant: return .restaurant
        case .party: return .event
        case .tasting: return .tasting
        }
    }
}

struct ExperienceRow: Identifiable {
    let id: UUID
    let pour: PourEntry
    let bottle: Bottle
    let rating: Double?
    let place: ExperiencePlace
    let notePreview: String
}

struct TopBottleRow: Identifiable {
    let id: UUID
    let bottle: Bottle
    let averageRating: Double?
    let tastingCount: Int
    let lastTasted: Date?
}

struct PreferenceSnapshotItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}

struct ExperienceTrendPoint: Identifiable {
    let id = UUID()
    let bucketDate: Date
    let avgRating: Double
}

@MainActor
final class InsightsDashboardViewModel: ObservableObject {
    @Published var ratingFilter: ExperienceRatingFilter = .all { didSet { recompute() } }
    @Published var selectedExpressions: Set<BottleType> = [] { didSet { recompute() } }
    @Published var selectedPlaces: Set<ExperiencePlace> = [] { didSet { recompute() } }
    @Published var timeRange: ExperienceTimeRange = .d90 { didSet { recompute() } }
    @Published var sortOption: ExperienceSortOption = .topRated { didSet { recompute() } }
    @Published var bottleRankingMetric: TopBottleRankingMetric = .avgRating { didSet { recompute() } }

    @Published private(set) var topExperience: ExperienceRow?
    @Published private(set) var topBottles: [TopBottleRow] = []
    @Published private(set) var topExperiences: [ExperienceRow] = []
    @Published private(set) var snapshotItems: [PreferenceSnapshotItem] = []
    @Published private(set) var trendPoints: [ExperienceTrendPoint] = []
    @Published private(set) var filteredTastingsCount: Int = 0

    private var sourceBottles: [Bottle] = []
    private var sourcePours: [PourEntry] = []

    func updateData(bottles: [Bottle], pours: [PourEntry]) {
        sourceBottles = bottles
        sourcePours = pours
        recompute()
    }

    func toggleExpression(_ expression: BottleType) {
        if selectedExpressions.contains(expression) {
            selectedExpressions.remove(expression)
        } else {
            selectedExpressions.insert(expression)
        }
    }

    func togglePlace(_ place: ExperiencePlace) {
        if selectedPlaces.contains(place) {
            selectedPlaces.remove(place)
        } else {
            selectedPlaces.insert(place)
        }
    }

    private func recompute() {
        let filtered = applyFilters(to: sourcePours)
        let experiences = filtered.map(makeExperienceRow).sorted { $0.pour.date > $1.pour.date }
        filteredTastingsCount = experiences.count

        let sortedExperiences = sortExperiences(experiences, by: sortOption)
        topExperience = sortedExperiences.first
        topExperiences = Array(sortedExperiences.prefix(10))
        topBottles = buildTopBottleRows(from: experiences, ranking: bottleRankingMetric)
        snapshotItems = buildSnapshot(from: experiences)
        trendPoints = buildTrend(from: experiences)
    }

    private func applyFilters(to pours: [PourEntry]) -> [PourEntry] {
        let cutoff = timeCutoff(for: timeRange)

        return pours.filter { pour in
            if let cutoff, pour.date < cutoff { return false }

            if !selectedExpressions.isEmpty, !selectedExpressions.contains(pour.bottle.type) {
                return false
            }

            let place = ExperiencePlace.from(context: pour.context)
            if !selectedPlaces.isEmpty, !selectedPlaces.contains(place) {
                return false
            }

            let rating = tastingRating(for: pour)
            switch ratingFilter {
            case .all:
                return true
            case .fourPlus:
                return (rating ?? 0) >= 4
            case .threePlus:
                return (rating ?? 0) >= 3
            case .unrated:
                return rating == nil
            }
        }
    }

    private func makeExperienceRow(from pour: PourEntry) -> ExperienceRow {
        let notes = pour.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = notes.isEmpty ? "No tasting notes yet." : String(notes.prefix(80))

        return ExperienceRow(
            id: pour.id,
            pour: pour,
            bottle: pour.bottle,
            rating: tastingRating(for: pour),
            place: ExperiencePlace.from(context: pour.context),
            notePreview: preview
        )
    }

    private func sortExperiences(_ experiences: [ExperienceRow], by sort: ExperienceSortOption) -> [ExperienceRow] {
        switch sort {
        case .topRated:
            return experiences.sorted {
                let lhs = $0.rating ?? -1
                let rhs = $1.rating ?? -1
                if lhs == rhs { return $0.pour.date > $1.pour.date }
                return lhs > rhs
            }
        case .mostLogged:
            let counts = Dictionary(grouping: experiences, by: { $0.bottle.id }).mapValues(\.count)
            return experiences.sorted {
                let lhs = counts[$0.bottle.id] ?? 0
                let rhs = counts[$1.bottle.id] ?? 0
                if lhs == rhs { return $0.pour.date > $1.pour.date }
                return lhs > rhs
            }
        case .mostRecent:
            return experiences.sorted { $0.pour.date > $1.pour.date }
        case .bestAtRestaurant:
            return experiences.sorted {
                let lhsRestaurant = $0.place == .restaurant
                let rhsRestaurant = $1.place == .restaurant
                if lhsRestaurant != rhsRestaurant { return lhsRestaurant }
                let lhsRating = $0.rating ?? -1
                let rhsRating = $1.rating ?? -1
                if lhsRating == rhsRating { return $0.pour.date > $1.pour.date }
                return lhsRating > rhsRating
            }
        }
    }

    private func buildTopBottleRows(from experiences: [ExperienceRow], ranking: TopBottleRankingMetric) -> [TopBottleRow] {
        let grouped = Dictionary(grouping: experiences, by: { $0.bottle.id })

        let rows = grouped.compactMap { _, rows -> TopBottleRow? in
            guard let first = rows.first else { return nil }
            let ratings = rows.compactMap(\.rating)
            let avg = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
            let lastDate = rows.map(\.pour.date).max()

            return TopBottleRow(
                id: first.bottle.id,
                bottle: first.bottle,
                averageRating: avg,
                tastingCount: rows.count,
                lastTasted: lastDate
            )
        }

        let sorted: [TopBottleRow]
        switch ranking {
        case .avgRating:
            sorted = rows.sorted {
                let lhs = $0.averageRating ?? -1
                let rhs = $1.averageRating ?? -1
                if lhs == rhs { return $0.tastingCount > $1.tastingCount }
                return lhs > rhs
            }
        case .mostLogged:
            sorted = rows.sorted {
                if $0.tastingCount == $1.tastingCount {
                    return ($0.lastTasted ?? .distantPast) > ($1.lastTasted ?? .distantPast)
                }
                return $0.tastingCount > $1.tastingCount
            }
        case .recency:
            sorted = rows.sorted {
                ($0.lastTasted ?? .distantPast) > ($1.lastTasted ?? .distantPast)
            }
        }

        return Array(sorted.prefix(10))
    }

    private func buildSnapshot(from experiences: [ExperienceRow]) -> [PreferenceSnapshotItem] {
        let highRated = experiences.filter { ($0.rating ?? 0) >= 4 }

        let preferredExpression = topValue(
            from: highRated.map { $0.bottle.type.rawValue }
        ) ?? "Need more rated tastings"

        let preferredRegion = topValue(
            from: highRated.map { $0.bottle.region.rawValue }
        ) ?? "Need more rated tastings"

        let favoriteSetting = bestSetting(from: highRated) ?? "Need more rated tastings"

        let tags = extractNoteTags(from: experiences.map(\.pour.notes))
        let tagsValue = tags.isEmpty ? "Add tasting notes to surface tags" : tags.joined(separator: " • ")

        return [
            PreferenceSnapshotItem(title: "Preferred Expression", value: preferredExpression, icon: "wineglass"),
            PreferenceSnapshotItem(title: "Preferred Region", value: preferredRegion, icon: "map"),
            PreferenceSnapshotItem(title: "Favorite Setting", value: favoriteSetting, icon: "mappin.and.ellipse"),
            PreferenceSnapshotItem(title: "Most Used Note Tags", value: tagsValue, icon: "text.bubble")
        ]
    }

    private func buildTrend(from experiences: [ExperienceRow]) -> [ExperienceTrendPoint] {
        let rated = experiences.filter { $0.rating != nil }
        guard rated.count >= 3 else { return [] }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: rated) { row in
            calendar.date(from: calendar.dateComponents([.year, .month], from: row.pour.date)) ?? row.pour.date
        }

        return grouped
            .map { date, rows in
                let values = rows.compactMap(\.rating)
                let average = values.reduce(0, +) / Double(values.count)
                return ExperienceTrendPoint(bucketDate: date, avgRating: average)
            }
            .sorted { $0.bucketDate < $1.bucketDate }
    }

    private func tastingRating(for pour: PourEntry) -> Double? {
        if let enjoyment = pour.enjoyment { return Double(enjoyment) }
        return pour.bottle.rating > 0 ? pour.bottle.rating : nil
    }

    private func timeCutoff(for range: ExperienceTimeRange) -> Date? {
        let calendar = Calendar.current
        let now = Date.now

        switch range {
        case .d30:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .d90:
            return calendar.date(byAdding: .day, value: -90, to: now)
        case .ytd:
            let comps = calendar.dateComponents([.year], from: now)
            return calendar.date(from: comps)
        case .all:
            return nil
        }
    }

    private func topValue(from values: [String]) -> String? {
        let cleaned = values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !cleaned.isEmpty else { return nil }
        let grouped = Dictionary(grouping: cleaned, by: { $0 }).mapValues(\.count)
        return grouped.max { $0.value < $1.value }?.key
    }

    private func bestSetting(from experiences: [ExperienceRow]) -> String? {
        let grouped = Dictionary(grouping: experiences, by: { $0.place })
        let scored = grouped.compactMap { key, rows -> (String, Double)? in
            let ratings = rows.compactMap(\.rating)
            guard !ratings.isEmpty else { return nil }
            let average = ratings.reduce(0, +) / Double(ratings.count)
            return (key.rawValue, average)
        }
        return scored.max { $0.1 < $1.1 }?.0
    }

    private func extractNoteTags(from notes: [String]) -> [String] {
        let stopWords: Set<String> = [
            "the", "and", "with", "this", "that", "from", "very", "just", "have", "notes", "taste", "tasting"
        ]

        var counts: [String: Int] = [:]

        for raw in notes {
            let lowered = raw.lowercased()
            let words = lowered
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 4 && !stopWords.contains($0) }

            for word in words {
                counts[word, default: 0] += 1
            }
        }

        return counts
            .sorted {
                if $0.value == $1.value { return $0.key < $1.key }
                return $0.value > $1.value
            }
            .prefix(3)
            .map { $0.key.capitalized }
    }
}
