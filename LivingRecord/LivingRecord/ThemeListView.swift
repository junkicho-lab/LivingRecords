import SwiftUI
import SwiftData

// S4 — 주제 탭. 통합된 주제별로 포착 보기.
struct ThemeListView: View {
    @Query(sort: \Theme.createdAt, order: .reverse) private var themes: [Theme]

    var body: some View {
        NavigationStack {
            List(themes) { t in
                NavigationLink {
                    ThemeDetailView(theme: t)
                } label: {
                    HStack {
                        Text(t.name).lineLimit(1)
                        Spacer()
                        Text("\(t.captures.count)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("주제")
            .overlay {
                if themes.isEmpty {
                    ContentUnavailableView("아직 주제가 없어요", systemImage: "circle.grid.cross",
                                           description: Text("포착이 쌓이면 비슷한 생각이 주제로 묶여요."))
                }
            }
        }
    }
}

struct ThemeDetailView: View {
    let theme: Theme

    var body: some View {
        List(theme.captures.sorted { $0.createdAt > $1.createdAt }) { c in
            VStack(alignment: .leading, spacing: 2) {
                Text(c.text)
                Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(theme.name)
    }
}
