import Foundation
import Combine

@MainActor
final class CreepStore: ObservableObject {
    @Published private(set) var items: [GroceryItem] = []

    static let freeItemLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("creep_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if items.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let now = Date()
        let monthAgo = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        items = [
            GroceryItem(name: "Eggs (dozen)", entries: [
                PriceEntry(price: 3.49, date: monthAgo),
                PriceEntry(price: 4.29, date: now)
            ]),
            GroceryItem(name: "Milk (gallon)", entries: [
                PriceEntry(price: 3.19, date: monthAgo),
                PriceEntry(price: 3.39, date: now)
            ])
        ]
        save()
    }

    func canAddItem(isPro: Bool) -> Bool {
        isPro || items.count < Self.freeItemLimit
    }

    @discardableResult
    func addItem(name: String, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddItem(isPro: isPro) else { return false }
        items.append(GroceryItem(name: trimmed))
        save()
        return true
    }

    func renameItem(_ id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].name = trimmed
        save()
    }

    func deleteItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func logPrice(for id: UUID, price: Double, date: Date = Date()) -> Bool {
        guard price > 0, let idx = items.firstIndex(where: { $0.id == id }) else { return false }
        items[idx].entries.append(PriceEntry(price: price, date: date))
        save()
        return true
    }

    func deleteEntry(itemId: UUID, entryId: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].entries.removeAll { $0.id == entryId }
        save()
    }

    func deleteAllData() {
        items = []
        seedDefaults()
    }

    var creepIndex: CreepIndexResult {
        CreepIndexCalculator.compute(items: items)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            items = decoded
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
