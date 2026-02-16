import Foundation
import SwiftData

@Model
final class WishlistItem {
    var id: UUID
    var name: String
    var brand: String?
    var typeRaw: String
    var nom: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        typeRaw: String = BottleType.blanco.rawValue,
        nom: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.typeRaw = typeRaw
        self.nom = nom
        self.createdAt = createdAt
    }

    var type: BottleType {
        get { BottleType(rawValue: typeRaw) ?? .blanco }
        set { typeRaw = newValue.rawValue }
    }
}
