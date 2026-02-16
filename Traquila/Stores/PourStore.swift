import Foundation
import SwiftData

@MainActor
final class PourStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createPour(
        date: Date,
        amountOZ: Double,
        serve: ServeStyle,
        contextTag: PourContext,
        enjoyment: Int?,
        nextDayFeel: Int?,
        notes: String,
        photoData: Data?,
        bottle: Bottle
    ) throws {
        let entry = PourEntry(
            date: date,
            amountOZ: amountOZ,
            serveRaw: serve.rawValue,
            contextRaw: contextTag.rawValue,
            enjoyment: enjoyment,
            nextDayFeel: nextDayFeel,
            notes: notes,
            photoData: photoData,
            bottle: bottle
        )
        context.insert(entry)
        try context.save()
    }

    func updatePour(
        _ pour: PourEntry,
        date: Date,
        amountOZ: Double,
        serve: ServeStyle,
        contextTag: PourContext,
        enjoyment: Int?,
        nextDayFeel: Int?,
        notes: String,
        photoData: Data?,
        bottle: Bottle
    ) throws {
        pour.date = date
        pour.amountOZ = amountOZ
        pour.serve = serve
        pour.context = contextTag
        pour.enjoyment = enjoyment
        pour.nextDayFeel = nextDayFeel
        pour.notes = notes
        pour.photoData = photoData
        pour.bottle = bottle
        try context.save()
    }

    func deletePour(_ pour: PourEntry) throws {
        context.delete(pour)
        try context.save()
    }
}
