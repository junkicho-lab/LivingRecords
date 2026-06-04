import WidgetKit
import SwiftUI
import AppIntents

// S14 — 포착 위젯. 한 탭(또는 꾹=봉인) → App Intent 실행 → 앱이 열리며 자동 녹음.
// 데이터를 안 읽는 런처라 App Group/타임라인 갱신 불필요(정적).
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry { let date: Date }

struct CaptureWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:                       // 잠금화면 원형
            Button(intent: StartCaptureIntent()) {
                Image(systemName: "mic.fill").font(.title2)
            }
            .buttonStyle(.plain)
        case .accessoryRectangular:                    // 잠금화면 가로
            Button(intent: StartCaptureIntent()) {
                Label("포착", systemImage: "mic.fill").font(.headline)
            }
            .buttonStyle(.plain)
        default:                                       // 홈 화면(systemSmall)
            VStack(spacing: 10) {
                Button(intent: StartCaptureIntent()) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(Color.blue, in: Circle())
                }
                .buttonStyle(.plain)
                Button(intent: StartSealedCaptureIntent()) {
                    Label("봉인", systemImage: "lock.fill").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
            }
        }
    }
}

struct CaptureWidget: Widget {
    let kind = "CaptureWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            CaptureWidgetEntryView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("포착")
        .description("한 탭으로 바로 포착을 시작해요. (꾹 누르듯 봉인도)")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
