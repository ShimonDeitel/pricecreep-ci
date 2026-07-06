import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CreepStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("creep_haptics_enabled") private var hapticsEnabled: Bool = true
    @State private var activeSheet: CreepSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .accessibilityIdentifier("hapticsToggle")
                }

                Section("Stats") {
                    HStack {
                        Text("Tracked Items")
                        Spacer()
                        Text("\(store.items.count)")
                            .foregroundStyle(CRTheme.inkFaded)
                    }
                    HStack {
                        Text("Creep Index")
                        Spacer()
                        Text(String(format: "%.0f", store.creepIndex.index))
                            .foregroundStyle(CRTheme.inkFaded)
                    }
                }

                Section("Creep Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(CRTheme.teal)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(CRTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/creep-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(CRTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all items and history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CreepStore())
        .environmentObject(PurchaseManager())
}
