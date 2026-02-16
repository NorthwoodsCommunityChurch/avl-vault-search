import SwiftUI

@main
struct VaultSearchApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView()
                .frame(minWidth: 800, minHeight: 550)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1100, height: 750)
    }
}
