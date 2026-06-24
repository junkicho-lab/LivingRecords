import Foundation
import AppIntents
import Observation

// S12 — 포착 도달성. 앱 밖(액션 버튼·Siri·AirPods·단축어)에서 '포착 시작'을 한 동작으로.
// 마이크는 앱 활성이 필요하므로 openAppWhenRun으로 포그라운드 진입 → 신호를 보고 자동 녹음.

// 앱 전역 런치 신호(싱글턴). App Intent가 set, SwiftUI가 관찰해 포착 화면을 열고 녹음 시작.
@Observable
final class AppLaunchState {
    static let shared = AppLaunchState()
    var startCapture = false      // 포착 시작 요청(트리거 → 자동 녹음)
    var startSealed = false       // 봉인 포착 여부
    var openCapture = false       // 포착 탭으로 이동만(리마인더 탭 → 녹음 안 함) — S13
    var openInsights = false      // 흐름 탭으로(되새김 알림 탭)
    var pendingDecisionThemeID: String?   // 저녁 결정 드립 → 결정 카드(대상 주제 ID)
    var pendingDecisionQuestion: String?  // 카드에 보일 거울형 질문
    private init() {}
}

struct StartCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "포착 시작"
    static let description = IntentDescription("녹음 화면을 열고 바로 포착을 시작합니다.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLaunchState.shared.startSealed = false
        AppLaunchState.shared.startCapture = true
        return .result()
    }
}

struct StartSealedCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "봉인 포착 시작"
    static let description = IntentDescription("기기 밖으로 나가지 않는 봉인 포착을 바로 시작합니다.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLaunchState.shared.startSealed = true
        AppLaunchState.shared.startCapture = true
        return .result()
    }
}

// Siri/단축어/액션 버튼에 노출되는 앱 단축어.
struct LivingRecordShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCaptureIntent(),
            phrases: ["\(.applicationName)에 포착", "\(.applicationName) 포착 시작", "\(.applicationName)에 기록"],
            shortTitle: "포착", systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: StartSealedCaptureIntent(),
            phrases: ["\(.applicationName)에 봉인 포착", "\(.applicationName) 봉인 기록"],
            shortTitle: "봉인 포착", systemImageName: "lock.fill"
        )
    }
}
