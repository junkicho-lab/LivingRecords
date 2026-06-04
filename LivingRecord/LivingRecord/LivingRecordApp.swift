import SwiftUI
import SwiftData

// Xcode가 생성한 동명 파일을 이 내용으로 교체할 것.
@main
struct LivingRecordApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Capture.self, Theme.self, Digest.self, Decision.self])
    }
}
