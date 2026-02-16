import Foundation
import SwiftData

enum MockDataSeeder {
    static func seedIfNeeded(context: ModelContext) throws {
        let bottleCount = try context.fetchCount(FetchDescriptor<Bottle>())
        let tastingCount = try context.fetchCount(FetchDescriptor<PourEntry>())

        guard bottleCount == 0, tastingCount == 0 else { return }

        let now = Date.now
        let calendar = Calendar.current

        let fortaleza = Bottle(
            name: "Fortaleza Blanco",
            brand: "Tequila Fortaleza",
            typeRaw: BottleType.blanco.rawValue,
            regionRaw: Region.lowlands.rawValue,
            nom: "1493",
            abv: 40,
            notes: "Cooked agave, citrus peel, black pepper.",
            rating: 4.8,
            bottleSizeML: 750
        )

        let elTesoro = Bottle(
            name: "El Tesoro Reposado",
            brand: "La Alteña",
            typeRaw: BottleType.reposado.rawValue,
            regionRaw: Region.highlands.rawValue,
            nom: "1139",
            abv: 40,
            notes: "Vanilla, oak, warm baking spice.",
            rating: 4.5,
            bottleSizeML: 750
        )

        let sieteLeguas = Bottle(
            name: "Siete Leguas Añejo",
            brand: "Siete Leguas",
            typeRaw: BottleType.anejo.rawValue,
            regionRaw: Region.lowlands.rawValue,
            nom: "1120",
            abv: 40,
            notes: "Caramel, dried fruit, gentle pepper finish.",
            rating: 4.4,
            bottleSizeML: 750
        )

        let vago = Bottle(
            name: "Mezcal Vago Espadín",
            brand: "Vago",
            typeRaw: BottleType.mezcal.rawValue,
            regionRaw: Region.otherUnknown.rawValue,
            abv: 45,
            notes: "Smoke, herbs, citrus zest.",
            rating: 4.2,
            bottleSizeML: 750
        )

        [fortaleza, elTesoro, sieteLeguas, vago].forEach { context.insert($0) }

        let tastings: [PourEntry] = [
            PourEntry(
                date: calendar.date(byAdding: .day, value: -50, to: now) ?? now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.restaurant.rawValue,
                enjoyment: 5,
                notes: "Bright agave and citrus. Excellent structure.",
                bottle: fortaleza
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -44, to: now) ?? now,
                amountOZ: 1.0,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.atHome.rawValue,
                enjoyment: 4,
                notes: "Peppery finish, very clean.",
                bottle: fortaleza
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -36, to: now) ?? now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.tasting.rawValue,
                enjoyment: 5,
                notes: "Top shelf tasting: agave-forward and elegant.",
                bottle: elTesoro
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -29, to: now) ?? now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.onTheRocks.rawValue,
                contextRaw: PourContext.bar.rawValue,
                enjoyment: 4,
                notes: "Vanilla and oak with smooth spice.",
                bottle: elTesoro
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -20, to: now) ?? now,
                amountOZ: 1.0,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.restaurant.rawValue,
                enjoyment: 4,
                notes: "Caramel and dried fruit. Long finish.",
                bottle: sieteLeguas
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -15, to: now) ?? now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.atHome.rawValue,
                enjoyment: 5,
                notes: "Outstanding balance; spice and oak in harmony.",
                bottle: sieteLeguas
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
                amountOZ: 1.0,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.tasting.rawValue,
                enjoyment: 4,
                notes: "Smoky and herbal with citrus lift.",
                bottle: vago
            ),
            PourEntry(
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                amountOZ: 1.5,
                serveRaw: ServeStyle.neat.rawValue,
                contextRaw: PourContext.restaurant.rawValue,
                enjoyment: 5,
                notes: "Memorable tasting; agave, pepper, and soft floral notes.",
                bottle: fortaleza
            )
        ]

        tastings.forEach { context.insert($0) }
        try context.save()
    }
}
