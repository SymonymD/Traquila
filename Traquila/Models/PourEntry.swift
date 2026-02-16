import Foundation
import SwiftData

@Model
final class PourEntry {
    var id: UUID
    var date: Date
    var amountOZ: Double
    var serveRaw: String
    var contextRaw: String
    var enjoyment: Int?
    var nextDayFeel: Int?
    var notes: String
    var photoData: Data?
    var createdAt: Date

    var bottle: Bottle

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amountOZ: Double,
        serveRaw: String,
        contextRaw: String,
        enjoyment: Int? = nil,
        nextDayFeel: Int? = nil,
        notes: String = "",
        photoData: Data? = nil,
        createdAt: Date = .now,
        bottle: Bottle
    ) {
        self.id = id
        self.date = date
        self.amountOZ = amountOZ
        self.serveRaw = serveRaw
        self.contextRaw = contextRaw
        self.enjoyment = enjoyment
        self.nextDayFeel = nextDayFeel
        self.notes = notes
        self.photoData = photoData
        self.createdAt = createdAt
        self.bottle = bottle
    }

    var serve: ServeStyle {
        get { ServeStyle(rawValue: serveRaw) ?? .neat }
        set { serveRaw = newValue.rawValue }
    }

    var context: PourContext {
        get { PourContext(rawValue: contextRaw) ?? .atHome }
        set { contextRaw = newValue.rawValue }
    }
}
