import Foundation
import SwiftData

@Model
final class Bottle {
    var id: UUID
    var name: String
    var brand: String?
    var typeRaw: String
    var regionRaw: String
    var nom: String?
    var abv: Double
    // Using Double instead of Decimal for better SwiftData compatibility and simpler JSON export.
    var pricePaid: Double?
    var purchaseDate: Date?
    var notes: String
    var rating: Double
    var bottleSizeML: Int?
    var openedDate: Date?
    var fillLevelPercent: Double
    var quantityOwned: Int
    var cellarLocation: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BottlePhoto.bottle)
    var photos: [BottlePhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \PourEntry.bottle)
    var pours: [PourEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        typeRaw: String = BottleType.blanco.rawValue,
        regionRaw: String = Region.otherUnknown.rawValue,
        nom: String? = nil,
        abv: Double = 40,
        pricePaid: Double? = nil,
        purchaseDate: Date? = nil,
        notes: String = "",
        rating: Double = 0,
        bottleSizeML: Int? = 750,
        openedDate: Date? = nil,
        fillLevelPercent: Double = 100,
        quantityOwned: Int = 1,
        cellarLocation: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.typeRaw = typeRaw
        self.regionRaw = regionRaw
        self.nom = nom
        self.abv = abv
        self.pricePaid = pricePaid
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.rating = rating
        self.bottleSizeML = bottleSizeML
        self.openedDate = openedDate
        self.fillLevelPercent = max(0, min(100, fillLevelPercent))
        self.quantityOwned = max(1, quantityOwned)
        self.cellarLocation = cellarLocation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: BottleType {
        get { BottleType(rawValue: typeRaw) ?? .blanco }
        set { typeRaw = newValue.rawValue }
    }

    var region: Region {
        get { Region(rawValue: regionRaw) ?? .otherUnknown }
        set { regionRaw = newValue.rawValue }
    }

    var heroPhotoData: Data? { photos.sorted { $0.createdAt < $1.createdAt }.first?.imageData }
}
