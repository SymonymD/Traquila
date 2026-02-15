import Foundation
import SwiftData

@Model
final class BottlePhoto {
    var id: UUID
    var imageData: Data
    var filename: String
    var createdAt: Date

    var bottle: Bottle?

    init(
        id: UUID = UUID(),
        imageData: Data,
        filename: String = "",
        createdAt: Date = .now,
        bottle: Bottle? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.filename = filename
        self.createdAt = createdAt
        self.bottle = bottle
    }
}
