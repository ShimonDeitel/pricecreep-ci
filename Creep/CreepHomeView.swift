import SwiftUI

struct CreepHomeView: View {
    @EnvironmentObject private var store: CreepStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: CreepSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                CRTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Creep")
                                .font(CRTheme.titleFont)
                                .foregroundStyle(CRTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddItem(isPro: purchases.isPro) {
                                    activeSheet = .addItem
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(CRTheme.teal)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addItemButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        creepIndexGauge

                        if store.items.isEmpty {
                            emptyState
                        } else {
                            itemsList
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addItem:
                    AddItemFormView()
                case .itemDetail(let item):
                    ItemDetailView(itemId: item.id)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: a "Creep Index" gauge — a single 0-100
    /// dial-style readout of how much the whole pantry has crept up in
    /// price, with a callout naming the single worst-offending item.
    private var creepIndexGauge: some View {
        let result = store.creepIndex
        return VStack(spacing: 12) {
            Text("CREEP INDEX")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.0)

            Gauge(value: min(max(result.index, 0), 100), in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [CRTheme.teal, CRTheme.mustardBright, CRTheme.danger]))
            .scaleEffect(2.2)
            .padding(.vertical, 14)
            .accessibilityIdentifier("creepIndexGauge")
            .accessibilityValue("\(Int(result.index))")

            Text(String(format: "%.0f", result.index))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            if let worstItem = result.worstItem, let pct = result.worstPercent {
                Text("Creepiest: \(worstItem.name) up \(String(format: "%.0f", pct))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityIdentifier("creepiestItemCallout")
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(CRTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private var itemsList: some View {
        VStack(spacing: 10) {
            ForEach(store.items) { item in
                ItemRow(item: item, onTap: { activeSheet = .itemDetail(item) })
            }
        }
        .padding(.horizontal, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.fill")
                .font(.system(size: 48))
                .foregroundStyle(CRTheme.inkFaded)
            Text("No staples tracked yet")
                .font(CRTheme.headlineFont)
                .foregroundStyle(CRTheme.ink)
            Text("Add an item to start watching its price creep.")
                .font(.subheadline)
                .foregroundStyle(CRTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

struct ItemRow: View {
    let item: GroceryItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(CRTheme.headlineFont)
                        .foregroundStyle(CRTheme.ink)
                    if let latest = item.latestPrice {
                        Text("$\(String(format: "%.2f", latest))")
                            .font(.caption)
                            .foregroundStyle(CRTheme.inkFaded)
                    }
                }
                Spacer()
                if let pct = item.creepPercent {
                    Text("\(pct > 0 ? "+" : "")\(String(format: "%.0f", pct))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(pct > 0 ? CRTheme.danger : CRTheme.success)
                        .accessibilityIdentifier("creepPercent_\(item.name)")
                }
            }
            .padding(12)
            .background(CRTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(CRTheme.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreepHomeView()
        .environmentObject(CreepStore())
        .environmentObject(PurchaseManager())
}
