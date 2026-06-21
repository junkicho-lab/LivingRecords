// CaptureWidgetBundle — 위젯 번들(포착 위젯 + 제어 센터 컨트롤).
import WidgetKit
import SwiftUI

@main
struct CaptureWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaptureWidget()
        CaptureWidgetControl()
        SealedCaptureWidgetControl()
    }
}
