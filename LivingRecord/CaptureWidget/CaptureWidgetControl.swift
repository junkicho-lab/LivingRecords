import AppIntents
import SwiftUI
import WidgetKit

// S14 — 제어 센터/잠금화면 컨트롤. 한 탭 → 포착 시작(앱 열리며 자동 녹음).
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
