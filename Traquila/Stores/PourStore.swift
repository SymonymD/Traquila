import Foundation
import SwiftData

@MainActor
final class PourStore {
    private let context: ModelContext
    private static let ozToML = 29.5735

    init(context: ModelContext) {
        self.context = context
    }

    func createPour(
        date: Date,
        amountOZ: Double,
        serve: ServeStyle,
        contextTag: PourContext,
        countAgainstCellar: Bool,
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

        if countAgainstCellar {
            applyVolumeChange(to: bottle, deltaML: -(amountOZ * Self.ozToML))
        }

        context.insert(entry)
        try context.save()
    }

    func updatePour(
        _ pour: PourEntry,
        date: Date,
        amountOZ: Double,
        serve: ServeStyle,
        contextTag: PourContext,
        countAgainstCellar: Bool,
        enjoyment: Int?,
        nextDayFeel: Int?,
        notes: String,
        photoData: Data?,
        bottle: Bottle
    ) throws {
        let previousBottle = pour.bottle
        let previousAmountOZ = pour.amountOZ
        let previouslyCounted = shouldCountAgainstCellar(pour)

        if previouslyCounted {
            applyVolumeChange(to: previousBottle, deltaML: previousAmountOZ * Self.ozToML)
        }

        pour.date = date
        pour.amountOZ = amountOZ
        pour.serve = serve
        pour.context = contextTag
        pour.enjoyment = enjoyment
        pour.nextDayFeel = nextDayFeel
        pour.notes = notes
        pour.photoData = photoData
        pour.bottle = bottle

        if countAgainstCellar {
            applyVolumeChange(to: bottle, deltaML: -(amountOZ * Self.ozToML))
        }

        try context.save()
    }

    func deletePour(_ pour: PourEntry) throws {
        if shouldCountAgainstCellar(pour) {
            applyVolumeChange(to: pour.bottle, deltaML: pour.amountOZ * Self.ozToML)
        }

        context.delete(pour)
        try context.save()
    }

    private func shouldCountAgainstCellar(_ pour: PourEntry) -> Bool {
        pour.context != .restaurant
    }

    private func applyVolumeChange(to bottle: Bottle, deltaML: Double) {
        let unitSize = Double(bottle.bottleSizeML ?? 750)
        let totalCapacity = max(unitSize * Double(max(1, bottle.quantityOwned)), 1)
        let currentRemaining = totalCapacity * (bottle.fillLevelPercent / 100)
        let nextRemaining = max(0, min(totalCapacity, currentRemaining + deltaML))
        bottle.fillLevelPercent = (nextRemaining / totalCapacity) * 100
        bottle.updatedAt = .now
    }
}
