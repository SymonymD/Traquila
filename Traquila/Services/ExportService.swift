import Foundation

struct ExportBlob: Codable {
    let exportedAt: Date
    let bottles: [BottleExport]
    let pours: [PourExport]
}

struct BottleExport: Codable {
    let id: UUID
    let name: String
    let brand: String?
    let type: String
    let region: String
    let nom: String?
    let abv: Double
    let pricePaid: Double?
    let purchaseDate: Date?
    let notes: String
    let rating: Double
    let bottleSizeML: Int?
    let photoFilenames: [String]
    let createdAt: Date
    let updatedAt: Date
}

struct PourExport: Codable {
    let id: UUID
    let date: Date
    let amountOZ: Double
    let serve: String
    let context: String
    let enjoyment: Int?
    let nextDayFeel: Int?
    let notes: String
    let bottleID: UUID
    let createdAt: Date
}

enum ExportService {
    static func makeExport(bottles: [Bottle], pours: [PourEntry]) throws -> URL {
        let blob = ExportBlob(
            exportedAt: .now,
            bottles: bottles.map { bottle in
                BottleExport(
                    id: bottle.id,
                    name: bottle.name,
                    brand: bottle.brand,
                    type: bottle.typeRaw,
                    region: bottle.regionRaw,
                    nom: bottle.nom,
                    abv: bottle.abv,
                    pricePaid: bottle.pricePaid,
                    purchaseDate: bottle.purchaseDate,
                    notes: bottle.notes,
                    rating: bottle.rating,
                    bottleSizeML: bottle.bottleSizeML,
                    photoFilenames: bottle.photos.map(\.filename),
                    createdAt: bottle.createdAt,
                    updatedAt: bottle.updatedAt
                )
            },
            pours: pours.map { pour in
                PourExport(
                    id: pour.id,
                    date: pour.date,
                    amountOZ: pour.amountOZ,
                    serve: pour.serveRaw,
                    context: pour.contextRaw,
                    enjoyment: pour.enjoyment,
                    nextDayFeel: pour.nextDayFeel,
                    notes: pour.notes,
                    bottleID: pour.bottle.id,
                    createdAt: pour.createdAt
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(blob)

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("traquila_export_\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: fileURL)
        return fileURL
    }
}
