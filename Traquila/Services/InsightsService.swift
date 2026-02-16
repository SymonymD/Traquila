import Foundation

struct InsightsSummary {
    let favoriteByEnjoymentName: String?
    let favoriteByEnjoymentScore: Double?
    let mostLoggedBottleName: String?
    let mostLoggedCount: Int
    let averageTastingRating: Double
    let preferredRegionName: String?
    let preferredRegionCount: Int
    let flavorHighlights: [String]
    let recommendedBottleNames: [String]
}

struct EnjoymentPoint: Identifiable {
    let id = UUID()
    let day: Date
    let value: Double
}

enum InsightsService {
    static func summary(bottles: [Bottle], pours: [PourEntry]) -> InsightsSummary {
        let enjoymentValues = pours.compactMap(\.enjoyment)
        let ratedBottleValues = bottles.map(\.rating).filter { $0 > 0 }
        let avgEnjoyment = enjoymentValues.isEmpty ? 0 : Double(enjoymentValues.reduce(0, +)) / Double(enjoymentValues.count)
        let avgBottleRating = ratedBottleValues.isEmpty ? 0 : ratedBottleValues.reduce(0, +) / Double(ratedBottleValues.count)
        let averageTastingRating = avgEnjoyment > 0 ? avgEnjoyment : avgBottleRating

        let grouped = Dictionary(grouping: pours, by: { $0.bottle.id })
        let topEntry = grouped.max { $0.value.count < $1.value.count }
        let topID = topEntry?.key
        let topCount = topEntry?.value.count ?? 0
        let topName = bottles.first(where: { $0.id == topID })?.name

        let enjoymentByBottle = Dictionary(grouping: pours.compactMap { pour -> (UUID, Int)? in
            guard let enjoyment = pour.enjoyment else { return nil }
            return (pour.bottle.id, enjoyment)
        }, by: { $0.0 })
        let favoriteByEnjoyment = enjoymentByBottle
            .mapValues { entries -> Double in
                let values = entries.map(\.1)
                return Double(values.reduce(0, +)) / Double(values.count)
            }
            .max { $0.value < $1.value }

        let favoriteBottleName = favoriteByEnjoyment.flatMap { best in
            bottles.first(where: { $0.id == best.key })?.name
        }

        let regionCounts = Dictionary(grouping: pours, by: { $0.bottle.region.rawValue }).mapValues(\.count)
        let preferredRegion = regionCounts.max { $0.value < $1.value }

        let recommended = bottles
            .filter { $0.rating >= 4 }
            .sorted {
                if $0.rating == $1.rating {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.rating > $1.rating
            }
            .map(\.name)
            .prefix(3)

        let flavorHighlights = extractFlavorHighlights(bottles: bottles, pours: pours, limit: 3)

        return InsightsSummary(
            favoriteByEnjoymentName: favoriteBottleName,
            favoriteByEnjoymentScore: favoriteByEnjoyment?.value,
            mostLoggedBottleName: topName,
            mostLoggedCount: topCount,
            averageTastingRating: averageTastingRating,
            preferredRegionName: preferredRegion?.key,
            preferredRegionCount: preferredRegion?.value ?? 0,
            flavorHighlights: flavorHighlights,
            recommendedBottleNames: Array(recommended)
        )
    }

    static func enjoymentTrend(pours: [PourEntry]) -> [EnjoymentPoint] {
        let calendar = Calendar.current
        let entries: [(Date, Int)] = pours.compactMap { pour in
            guard let enjoyment = pour.enjoyment else { return nil }
            let day = calendar.startOfDay(for: pour.date)
            return (day, enjoyment)
        }
        let grouped = Dictionary(grouping: entries, by: { $0.0 })

        return grouped.keys.sorted().map { day in
            let values = grouped[day]?.map { Double($0.1) } ?? []
            let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            return EnjoymentPoint(day: day, value: avg)
        }
    }

    static func sampleSummary() -> InsightsSummary {
        InsightsSummary(
            favoriteByEnjoymentName: "Fortaleza Blanco",
            favoriteByEnjoymentScore: 4.8,
            mostLoggedBottleName: "El Tesoro Reposado",
            mostLoggedCount: 6,
            averageTastingRating: 4.4,
            preferredRegionName: Region.highlands.rawValue,
            preferredRegionCount: 9,
            flavorHighlights: ["Cooked Agave", "Citrus", "Pepper"],
            recommendedBottleNames: ["Fortaleza Blanco", "G4 Añejo", "Siete Leguas Reposado"]
        )
    }

    static func sampleEnjoymentTrend(now: Date = .now) -> [EnjoymentPoint] {
        let calendar = Calendar.current
        let offsetsAndValues: [(Int, Double)] = [(-18, 3.9), (-14, 4.1), (-10, 4.0), (-6, 4.4), (-3, 4.6), (-1, 4.5)]

        return offsetsAndValues.compactMap { offset, value in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            return EnjoymentPoint(day: calendar.startOfDay(for: day), value: value)
        }
    }

    private static func extractFlavorHighlights(bottles: [Bottle], pours: [PourEntry], limit: Int) -> [String] {
        let flavorTerms = [
            "agave", "vanilla", "citrus", "pepper", "oak", "caramel",
            "smoke", "spice", "floral", "herbal", "fruit", "earthy"
        ]
        let notesText = (bottles.map(\.notes) + pours.map(\.notes))
            .joined(separator: " ")
            .lowercased()

        let counts = flavorTerms.reduce(into: [String: Int]()) { partial, term in
            let hits = notesText.components(separatedBy: term).count - 1
            if hits > 0 {
                partial[term] = hits
            }
        }

        return counts
            .sorted {
                if $0.value == $1.value { return $0.key < $1.key }
                return $0.value > $1.value
            }
            .prefix(limit)
            .map { $0.key.capitalized }
    }
}
