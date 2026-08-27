import SwiftUI

@main
struct MagicShopApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ProvisionalRootView()
                .environmentObject(model)
        }
    }
}
