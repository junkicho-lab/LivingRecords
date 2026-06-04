import SwiftUI

// S1 셸 — 4탭. 빈 영역 가로 스와이프로 옆 탭 이동(목록 행 스와이프와 충돌 안 하게 배경에만).
struct ContentView: View {
    @State private var tab = 0
    private let tabCount = 4

    var body: some View {
        TabView(selection: $tab) {
            CaptureView()
                .tabSwipe($tab, count: tabCount)
                .tabItem { Label("포착", systemImage: "mic.circle") }.tag(0)
            CaptureListView()
                .tabSwipe($tab, count: tabCount)
                .tabItem { Label("기록", systemImage: "list.bullet") }.tag(1)
            ThemeListView()
                .tabSwipe($tab, count: tabCount)
                .tabItem { Label("주제", systemImage: "circle.grid.cross") }.tag(2)
            DigestListView()
                .tabSwipe($tab, count: tabCount)
                .tabItem { Label("정리", systemImage: "doc.text") }.tag(3)
        }
    }
}

extension View {
    /// 빈 영역(배경) 가로 스와이프로 인접 탭 전환. 좌→다음, 우→이전.
    func tabSwipe(_ selection: Binding<Int>, count: Int) -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { v in
                            guard abs(v.translation.width) > abs(v.translation.height),
                                  abs(v.translation.width) > 60 else { return }
                            let dir = v.translation.width < 0 ? 1 : -1
                            selection.wrappedValue = max(0, min(count - 1, selection.wrappedValue + dir))
                        }
                )
        )
    }
}

#Preview { ContentView() }
