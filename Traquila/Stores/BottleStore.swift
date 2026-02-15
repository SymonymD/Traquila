import Foundation
import SwiftData

@MainActor
final class BottleStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save() throws {
        try context.save()
    }

    func createBottle(
        name: String,
        brand: String?,
        type: BottleType,
        region: Region,
        nom: String?,
        abv: Double,
        pricePaid: Double?,
        purchaseDate: Date?,
        notes: String,
        rating: Double,
        bottleSizeML: Int?,
        photoData: [Data]
    ) throws {
        let bottle = Bottle(
            name: name,
            brand: brand?.nilIfEmpty,
            typeRaw: type.rawValue,
            regionRaw: region.rawValue,
            nom: nom?.nilIfEmpty,
            abv: abv,
            pricePaid: pricePaid,
            purchaseDate: purchaseDate,
            notes: notes,
            rating: rating,
            bottleSizeML: bottleSizeML
        )

        for (index, data) in photoData.prefix(3).enumerated() {
            let filename = "bottle_\(bottle.id.uuidString)_\(index).jpg"
            bottle.photos.append(BottlePhoto(imageData: data, filename: filename, bottle: bottle))
        }

        context.insert(bottle)
        try context.save()
    }

    func updateBottle(
        _ bottle: Bottle,
        name: String,
        brand: String?,
        type: BottleType,
        region: Region,
        nom: String?,
        abv: Double,
        pricePaid: Double?,
        purchaseDate: Date?,
        notes: String,
        rating: Double,
        bottleSizeML: Int?,
        photoData: [Data]
    ) throws {
        bottle.name = name
        bottle.brand = brand?.nilIfEmpty
        bottle.type = type
        bottle.region = region
        bottle.nom = nom?.nilIfEmpty
        bottle.abv = abv
        bottle.pricePaid = pricePaid
        bottle.purchaseDate = purchaseDate
        bottle.notes = notes
        bottle.rating = rating
        bottle.bottleSizeML = bottleSizeML
        bottle.updatedAt = .now

        for photo in bottle.photos {
            context.delete(photo)
        }
        bottle.photos.removeAll()

        for (index, data) in photoData.prefix(3).enumerated() {
            let filename = "bottle_\(bottle.id.uuidString)_\(index).jpg"
            bottle.photos.append(BottlePhoto(imageData: data, filename: filename, bottle: bottle))
        }

        try context.save()
    }

    func deleteBottle(_ bottle: Bottle) throws {
        context.delete(bottle)
        try context.save()
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
