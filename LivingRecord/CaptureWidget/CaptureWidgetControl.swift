import AppIntents
import SwiftUI
import WidgetKit

// S14 — 제어 센터/잠금화면 컨트롤. 한 탭 → 포착 시작(앱 열리며 자동 녹음).
// 컨트롤은 단일 액션이므로 일반/봉인을 별도 컨트롤로 제공 → 사용자가 원하는 걸 골라 추가.
struct CaptureWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "gyeol.LivingRecord.CaptureControl") {
            ControlWidgetButton(action: StartCaptureIntent()) {
                Label("포착", systemImage: "mic.fill")
            }
        }
        .displayName("포착")
        .description("한 탭으로 포착을 시작해요.")
    }
}

// 봉인 포착 컨트롤(별도) — 기기 밖으로 안 나가는 봉인 포착을 한 탭으로.
struct SealedCaptureWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "gyeol.LivingRecord.SealedCaptureControl") {
            ControlWidgetButton(action: StartSealedCaptureIntent()) {
                Label("봉인 포착", systemImage: "lock.fill")
            }
        }
        .displayName("봉인 포착")
        .description("한 탭으로 봉인 포착을 시작해요. (기기 밖으로 안 나감)")
    }
}
