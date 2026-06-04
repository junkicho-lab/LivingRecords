import SwiftUI
import SwiftData

@main
struct LivingRecordApp: App {
    @State private var vault = VaultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Capture.self, Theme.self, Digest.self, Decision.self])
        .environment(vault)
    }
}
