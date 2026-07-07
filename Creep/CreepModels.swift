import Foundation

/// A single price observation for an item, logged on a shopping trip.
struct PriceEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var price: Double
    var date: Date

    init(id: UUID = UUID(), price: Double, date: Date = Date()) {
        self.id = id
        self.price = price
        self.date = date
    }
}

/// A staple grocery item the user tracks over time, e.g. "Eggs (dozen)".
struct GroceryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var entries: [PriceEntry]

    init(id: UUID = UUID(), name: String, entries: [PriceEntry] = []) {
        self.id = id
        self.name = name
        self.entries = entries
    }

    private var sortedEntries: [PriceEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var firstPrice: Double? { sortedEntries.first?.price }
    var latestPrice: Double? { sortedEntries.last?.price }

    /// Percent change from the first logged price to the latest — the core
    /// "price creep" metric. Positive means the price has crept up.
    var creepPercent: Double? {
        guard entries.count >= 2, let first = firstPrice, let latest = latestPrice, first > 0 else { return nil }
        return ((latest - first) / first) * 100
    }

    var isCreepingUp: Bool { (creepPercent ?? 0) > 0 }
}

/// Aggregate stats used by the quirky "Creep Index" feature: a single
/// number (0-100) that captures how much the whole pantry has crept up in
/// price, plus a callout for the single worst offender.
struct CreepIndexResult {
    let index: Double
    let worstItem: GroceryItem?
    let worstPercent: Double?
}

enum CreepIndexCalculator {
    /// Averages each tracked item's creep percent (clamped to a sane range)
    /// into a single 0-100 "index" for a satisfying one-number readout.
    static func compute(items: [GroceryItem]) -> CreepIndexResult {
        let withCreep = items.compactMap { item -> (GroceryItem, Double)? in
            guard let pct = item.creepPercent else { return nil }
            return (item, pct)
        }
        guard !withCreep.isEmpty else {
            return CreepIndexResult(index: 0, worstItem: nil, worstPercent: nil)
        }
        let avg = withCreep.reduce(0.0) { $0 + $1.1 } / Double(withCreep.count)
        let clamped = max(0, min(avg, 100))
        let worst = withCreep.max { $0.1 < $1.1 }
        return CreepIndexResult(index: clamped, worstItem: worst?.0, worstPercent: worst?.1)
    }
}
