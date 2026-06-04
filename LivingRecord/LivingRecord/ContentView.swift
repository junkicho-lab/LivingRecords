import SwiftUI

// S0 셸 — 자리표시 탭. 슬라이스에서 실제 화면으로 교체.
struct ContentView: View {
    var body: some View {
        TabView {
            Text("포착 (S1)")
                .tabItem { Label("포착", systemImage: "mic.circle") }
            Text("기록 (S1)")
                .tabItem { Label("기록", systemImage: "list.bullet") }
            Text("주제 (S4)")
                .tabItem { Label("주제", systemImage: "circle.grid.cross") }
            Text("정리 (S5/S6)")
                .tabItem { Label("정리", systemImage: "doc.text") }
        }
    }
}

#Preview { ContentView() }
