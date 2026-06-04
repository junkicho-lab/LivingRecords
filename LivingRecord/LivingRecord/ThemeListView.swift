import SwiftUI
import SwiftData

// S4 — 주제 탭. 통합된 주제별로 포착 보기 + 큐레이션(이름변경/합치기/이동).
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
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Theme.createdAt) private var allThemes: [Theme]
    @State private var renaming = false
    @State private var newName = ""
    @State private var merging = false
    @State private var moving = false
    @State private var moveTarget: Capture?

    private var otherThemes: [Theme] { allThemes.filter { $0.id != theme.id } }

    var body: some View {
        List {
            ForEach(theme.captures.sorted { $0.createdAt > $1.createdAt }) { c in
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.text)
                    Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("이동") { moveTarget = c; moving = true }.tint(.blue)
                }
            }
        }
        .navigationTitle(theme.name)
        .toolbar {
            Menu {
                Button { newName = theme.name; renaming = true } label: { Label("이름 변경", systemImage: "pencil") }
                if !otherThemes.isEmpty {
                    Button { merging = true } label: { Label("다른 주제로 합치기", systemImage: "arrow.triangle.merge") }
                }
            } label: { Image(systemName: "ellipsis.circle") }
        }
        .alert("주제 이름 변경", isPresented: $renaming) {
            TextField("이름", text: $newName)
            Button("저장") {
                let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !n.isEmpty { theme.name = n; try? context.save() }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("어느 주제로 합칠까요?", isPresented: $merging, titleVisibility: .visible) {
            ForEach(otherThemes) { target in
                Button(target.name) { merge(into: target) }
            }
        }
        .confirmationDialog("이 포착을 어디로 옮길까요?", isPresented: $moving, titleVisibility: .visible) {
            ForEach(otherThemes) { target in
                Button(target.name) { if let c = moveTarget { move(c, to: target) } }
            }
            Button("새 주제로 추출") { if let c = moveTarget { extractToNew(c) } }
        }
    }

    private func merge(into target: Theme) {
        for c in Array(theme.captures) { c.theme = target }
        context.delete(theme)
        try? context.save()
        dismiss()
    }

    private func move(_ c: Capture, to target: Theme) {
        c.theme = target
        try? context.save()
        if theme.captures.isEmpty { context.delete(theme); try? context.save(); dismiss() }
    }

    private func extractToNew(_ c: Capture) {
        let t = Theme(name: Consolidator.placeholderName(c.text))
        context.insert(t)
        c.theme = t
        try? context.save()
        if theme.captures.isEmpty { context.delete(theme); try? context.save(); dismiss() }
    }
}
