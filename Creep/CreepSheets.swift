import SwiftUI

enum CreepSheet: Identifiable {
    case addItem
    case itemDetail(GroceryItem)
    case paywall

    var id: String {
        switch self {
        case .addItem: return "addItem"
        case .itemDetail(let i): return "detail-\(i.id)"
        case .paywall: return "paywall"
        }
    }
}

struct AddItemFormView: View {
    @EnvironmentObject private var store: CreepStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var priceText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Staple") {
                    TextField("Item name (e.g. Bread)", text: $name)
                        .accessibilityIdentifier("itemNameField")
                    TextField("Current price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("itemPriceField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard store.addItem(name: name, isPro: purchases.isPro) else { return }
                        if let price = Double(priceText), price > 0, let added = store.items.last {
                            store.logPrice(for: added.id, price: price)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(priceText) == nil)
                    .accessibilityIdentifier("saveItemButton")
                }
            }
        }
    }
}

struct ItemDetailView: View {
    @EnvironmentObject private var store: CreepStore
    @Environment(\.dismiss) private var dismiss

    let itemId: UUID
    @State private var newPriceText: String = ""
    @State private var renameText: String = ""

    private var item: GroceryItem? {
        store.items.first { $0.id == itemId }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let item {
                    Section("Item") {
                        TextField("Name", text: $renameText)
                            .accessibilityIdentifier("renameItemField")
                            .onSubmit {
                                store.renameItem(item.id, name: renameText)
                            }
                    }

                    Section("Log a Price") {
                        TextField("New price", text: $newPriceText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("newPriceField")
                        Button("Log Price") {
                            if let price = Double(newPriceText) {
                                store.logPrice(for: item.id, price: price)
                                newPriceText = ""
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(Double(newPriceText) == nil)
                        .accessibilityIdentifier("logPriceButton")
                    }

                    if let creep = item.creepPercent {
                        Section("Price Creep") {
                            Text(String(format: "%.1f%% since first logged", creep))
                                .foregroundStyle(creep > 0 ? CRTheme.danger : CRTheme.success)
                                .accessibilityIdentifier("itemCreepPercent")
                        }
                    }

                    Section("History") {
                        ForEach(item.entries.sorted(by: { $0.date > $1.date })) { entry in
                            HStack {
                                Text(entry.date, style: .date)
                                Spacer()
                                Text("$\(String(format: "%.2f", entry.price))")
                                    .foregroundStyle(CRTheme.inkFaded)
                            }
                        }
                    }

                    Section {
                        Button("Delete Item", role: .destructive) {
                            store.deleteItem(item.id)
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteItemButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(item?.name ?? "Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.plain)
                }
            }
            .onAppear {
                renameText = item?.name ?? ""
            }
        }
    }
}
