import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CreepHomeView()
                .tabItem {
                    Label("Groceries", systemImage: "cart.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(CRTheme.teal)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(CRTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(CreepStore())
        .environmentObject(PurchaseManager())
}
