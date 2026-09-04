import SwiftUI

@main
struct MagicShopApp: App {
    @StateObject private var model = AppModel.makeApplicationModel()

    var body: some Scene {
        WindowGroup {
            ProvisionalRootView()
                .environmentObject(model)
        }
    }
}
