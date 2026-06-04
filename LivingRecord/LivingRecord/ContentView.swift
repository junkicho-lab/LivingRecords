import SwiftUI

// S1 셸 — 포착/기록은 실제 화면, 주제/정리는 자리표시.
struct ContentView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("포착", systemImage: "mic.circle") }
            CaptureListView()
                .tabItem { Label("기록", systemImage: "list.bullet") }
            ThemeListView()
                .tabItem { Label("주제", systemImage: "circle.grid.cross") }
            Text("정리 (S5/S6)")
                .tabItem { Label("정리", systemImage: "doc.text") }
        }
    }
}

#Preview { ContentView() }
