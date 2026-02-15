import Foundation

struct InsightsSummary {
    let totalWeek: Int
    let totalMonth: Int
    let averageEnjoyment: Double
    let mostLoggedBottleName: String?
    let totalSpend: Double
    let estimatedCostPerPour: Double?
}

struct EnjoymentPoint: Identifiable {
    let id = UUID()
    let day: Date
    let value: Double
}

enum InsightsService {
    static func summary(bottles: [Bottle], pours: [PourEntry], now: Date = .now) -> InsightsSummary {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let week = pours.filter { $0.date >= weekStart }.count
        let month = pours.filter { $0.date >= monthStart }.count

        let enjoymentValues = pours.compactMap(\.enjoyment)
        let avgEnjoyment = enjoymentValues.isEmpty ? 0 : Double(enjoymentValues.reduce(0, +)) / Double(enjoymentValues.count)

        let grouped = Dictionary(grouping: pours, by: { $0.bottle.id })
        let topID = grouped.max { $0.value.count < $1.value.count }?.key
        let topName = bottles.first(where: { $0.id == topID })?.name

        let spend = bottles.compactMap(\.pricePaid).reduce(0, +)

        let totalCostedPours = bottles.reduce(0.0) { partial, bottle in
            guard let price = bottle.pricePaid, let size = bottle.bottleSizeML, size > 0 else { return partial }
            let ounces = Double(size) / 29.5735
            guard ounces > 0 else { return partial }
            let poursForBottle = pours.filter { $0.bottle.id == bottle.id }.map(\.amountOZ).reduce(0, +)
            guard poursForBottle > 0 else { return partial }
            return partial + (price / ounces) * poursForBottle
        }
        let totalOunces = pours.map(\.amountOZ).reduce(0, +)
        let costPerPour = totalOunces > 0 ? totalCostedPours / totalOunces : nil

        return InsightsSummary(
            totalWeek: week,
            totalMonth: month,
            averageEnjoyment: avgEnjoyment,
            mostLoggedBottleName: topName,
            totalSpend: spend,
            estimatedCostPerPour: costPerPour
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
}
