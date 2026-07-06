import SwiftUI

@main
struct CreepApp: App {
    @StateObject private var store = CreepStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
