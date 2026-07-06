import XCTest
@testable import Creep

final class CreepTests: XCTestCase {
    var store: CreepStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = CreepStore()
        store.deleteAllData()
        for i in store.items { store.deleteItem(i.id) }
    }

    @MainActor
    func testAddItem() {
        let added = store.addItem(name: "Bread", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].name, "Bread")
    }

    @MainActor
    func testAddItemRejectsEmptyName() {
        let added = store.addItem(name: "   ", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksFourthItem() {
        _ = store.addItem(name: "A", isPro: false)
        _ = store.addItem(name: "B", isPro: false)
        _ = store.addItem(name: "C", isPro: false)
        XCTAssertFalse(store.canAddItem(isPro: false))
        let fourth = store.addItem(name: "D", isPro: false)
        XCTAssertFalse(fourth)
        XCTAssertEqual(store.items.count, 3)
    }

    @MainActor
    func testProAllowsUnlimitedItems() {
        _ = store.addItem(name: "A", isPro: true)
        _ = store.addItem(name: "B", isPro: true)
        _ = store.addItem(name: "C", isPro: true)
        let fourth = store.addItem(name: "D", isPro: true)
        XCTAssertTrue(fourth)
        XCTAssertEqual(store.items.count, 4)
    }

    @MainActor
    func testRenameItem() {
        _ = store.addItem(name: "Bread", isPro: false)
        let id = store.items[0].id
        store.renameItem(id, name: "Sourdough")
        XCTAssertEqual(store.items[0].name, "Sourdough")
    }

    @MainActor
    func testDeleteItem() {
        _ = store.addItem(name: "Bread", isPro: false)
        let id = store.items[0].id
        store.deleteItem(id)
        XCTAssertTrue(store.items.isEmpty)
    }

    @MainActor
    func testLogPriceAddsEntry() {
        _ = store.addItem(name: "Bread", isPro: false)
        let id = store.items[0].id
        let ok = store.logPrice(for: id, price: 2.99)
        XCTAssertTrue(ok)
        XCTAssertEqual(store.items[0].entries.count, 1)
        XCTAssertEqual(store.items[0].latestPrice, 2.99)
    }

    @MainActor
    func testLogPriceRejectsNonPositive() {
        _ = store.addItem(name: "Bread", isPro: false)
        let id = store.items[0].id
        let ok = store.logPrice(for: id, price: 0)
        XCTAssertFalse(ok)
    }

    @MainActor
    func testDeleteEntry() {
        _ = store.addItem(name: "Bread", isPro: false)
        let id = store.items[0].id
        store.logPrice(for: id, price: 2.99)
        let entryId = store.items[0].entries[0].id
        store.deleteEntry(itemId: id, entryId: entryId)
        XCTAssertTrue(store.items[0].entries.isEmpty)
    }

    // MARK: - Creep math

    func testCreepPercentPositiveWhenPriceRises() {
        var item = GroceryItem(name: "Eggs")
        item.entries = [
            PriceEntry(price: 3.00, date: Date(timeIntervalSince1970: 0)),
            PriceEntry(price: 3.60, date: Date(timeIntervalSince1970: 1000))
        ]
        XCTAssertEqual(item.creepPercent!, 20.0, accuracy: 0.001)
        XCTAssertTrue(item.isCreepingUp)
    }

    func testCreepPercentNegativeWhenPriceFalls() {
        var item = GroceryItem(name: "Eggs")
        item.entries = [
            PriceEntry(price: 4.00, date: Date(timeIntervalSince1970: 0)),
            PriceEntry(price: 3.00, date: Date(timeIntervalSince1970: 1000))
        ]
        XCTAssertEqual(item.creepPercent!, -25.0, accuracy: 0.001)
        XCTAssertFalse(item.isCreepingUp)
    }

    func testCreepPercentNilWithFewerThanTwoEntries() {
        var item = GroceryItem(name: "Eggs")
        item.entries = [PriceEntry(price: 3.00, date: Date())]
        XCTAssertNil(item.creepPercent)
    }

    func testCreepIndexAveragesAcrossItems() {
        var a = GroceryItem(name: "A")
        a.entries = [PriceEntry(price: 2.00, date: Date(timeIntervalSince1970: 0)), PriceEntry(price: 2.20, date: Date(timeIntervalSince1970: 1000))] // +10%
        var b = GroceryItem(name: "B")
        b.entries = [PriceEntry(price: 4.00, date: Date(timeIntervalSince1970: 0)), PriceEntry(price: 4.80, date: Date(timeIntervalSince1970: 1000))] // +20%
        let result = CreepIndexCalculator.compute(items: [a, b])
        XCTAssertEqual(result.index, 15.0, accuracy: 0.001)
        XCTAssertEqual(result.worstItem?.name, "B")
        XCTAssertEqual(result.worstPercent!, 20.0, accuracy: 0.001)
    }

    func testCreepIndexZeroWhenNoQualifyingItems() {
        let item = GroceryItem(name: "Solo")
        let result = CreepIndexCalculator.compute(items: [item])
        XCTAssertEqual(result.index, 0)
        XCTAssertNil(result.worstItem)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addItem(name: "Extra", isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.items.isEmpty)
    }
}
