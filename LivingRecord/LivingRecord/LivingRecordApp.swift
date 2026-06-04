import SwiftUI
import SwiftData

@main
struct LivingRecordApp: App {
    @State private var vault = VaultStore()
    @State private var consent = CloudConsent()
    @State private var launch = AppLaunchState.shared    // S12 — App Intent 런치 신호
    @State private var reminders = ReminderStore()       // S13 — 저녁 회고 리마인더
    @State private var templates = TemplateStore()       // 정리 템플릿 활성 선택

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Capture.self, Theme.self, Digest.self, Decision.self, Transmission.self, Commitment.self, CustomTemplate.self])
        .environment(vault)
        .environment(consent)
        .environment(launch)
        .environment(reminders)
        .environment(templates)
    }
}
