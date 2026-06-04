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
        // 전체 영역 가로 스와이프(세로 스크롤과 구분: 가로가 1.5배 이상 + 70pt↑). 행은 길게누르기로 동작.
        // contentShape: VStack 등 빈 공간(Spacer)도 터치 받게 — 포착 탭 스와이프 위해 필요.
        contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { v in
                    guard abs(v.translation.width) > abs(v.translation.height) * 1.5,
                          abs(v.translation.width) > 70 else { return }
                    let dir = v.translation.width < 0 ? 1 : -1
                    selection.wrappedValue = max(0, min(count - 1, selection.wrappedValue + dir))
                }
        )
    }
}

#Preview { ContentView() }
