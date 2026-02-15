//
//  TraquilaTests.swift
//  TraquilaTests
//
//  Created by John Fentner on 2/15/26.
//

import Foundation
import Testing
@testable import Traquila

struct TraquilaTests {
    @Test func insightsSummaryAggregates() async throws {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let bottleA = Bottle(
            name: "Cascabel Blanco",
            brand: "Casa Azul",
            typeRaw: BottleType.blanco.rawValue,
            regionRaw: Region.highlands.rawValue,
            abv: 40,
            pricePaid: 60,
            bottleSizeML: 750
        )
        let bottleB = Bottle(
            name: "Sol Reposado",
            brand: "El Campo",
            typeRaw: BottleType.reposado.rawValue,
            regionRaw: Region.lowlands.rawValue,
            abv: 40,
            pricePaid: 80,
            bottleSizeML: 750
        )

        let pours: [PourEntry] = [
            PourEntry(
                date: now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.atHome.rawValue,
                enjoyment: 5,
                nextDayFeel: 4,
                notes: "",
                bottle: bottleA
            ),
            PourEntry(
                date: now.addingTimeInterval(-24 * 60 * 60),
                amountOZ: 1.0,
                serveRaw: ServeStyle.paloma.rawValue,
                contextRaw: PourContext.bar.rawValue,
                enjoyment: 3,
                nextDayFeel: 3,
                notes: "",
                bottle: bottleA
            ),
            PourEntry(
                date: now.addingTimeInterval(-40 * 24 * 60 * 60),
                amountOZ: 2.0,
                serveRaw: ServeStyle.margarita.rawValue,
                contextRaw: PourContext.party.rawValue,
                enjoyment: nil,
                nextDayFeel: nil,
                notes: "",
                bottle: bottleB
            )
        ]

        let summary = InsightsService.summary(
            bottles: [bottleA, bottleB],
            pours: pours,
            now: now
        )

        #expect(summary.totalWeek == 2)
        #expect(summary.totalMonth == 2)
        #expect(summary.averageEnjoyment == 4)
        #expect(summary.mostLoggedBottleName == "Cascabel Blanco")
        #expect(summary.totalSpend == 140)
        #expect(summary.estimatedCostPerPour != nil)
    }

    @Test func enjoymentTrendGroupsByDay() async throws {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let bottle = Bottle(name: "Test Bottle", typeRaw: BottleType.blanco.rawValue, regionRaw: Region.highlands.rawValue)
        let pours: [PourEntry] = [
            PourEntry(date: now, amountOZ: 1, serveRaw: ServeStyle.neat.rawValue, contextRaw: PourContext.atHome.rawValue, enjoyment: 5, bottle: bottle),
            PourEntry(date: now.addingTimeInterval(-3600), amountOZ: 1, serveRaw: ServeStyle.neat.rawValue, contextRaw: PourContext.atHome.rawValue, enjoyment: 3, bottle: bottle),
            PourEntry(date: now.addingTimeInterval(-24 * 60 * 60), amountOZ: 1, serveRaw: ServeStyle.neat.rawValue, contextRaw: PourContext.atHome.rawValue, enjoyment: 4, bottle: bottle)
        ]

        let trend = InsightsService.enjoymentTrend(pours: pours)

        #expect(trend.count == 2)
        #expect(trend.last?.value == 4)
    }

}
