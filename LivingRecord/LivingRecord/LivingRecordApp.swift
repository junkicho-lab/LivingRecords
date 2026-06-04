import SwiftUI
import SwiftData

@main
struct LivingRecordApp: App {
    @State private var vault = VaultStore()
    @State private var consent = CloudConsent()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Capture.self, Theme.self, Digest.self, Decision.self, Transmission.self])
        .environment(vault)
        .environment(consent)
    }
}
