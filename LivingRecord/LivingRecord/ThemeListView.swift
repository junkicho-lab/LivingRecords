import SwiftUI
import SwiftData

// S4 — 주제 탭. 통합된 주제별 포착 + 큐레이션(이름변경/합치기) + 기록 재배치(이동/다중이동/순서).
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
                        Text("\(t.captures.count)").font(.caption).foregroundStyle(.secondary)
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
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<PersistentIdentifier>()
    @State private var renaming = false
    @State private var newName = ""
    @State private var merging = false
    @State private var moving = false
    @State private var moveTargets: [Capture] = []

    private var sorted: [Capture] { theme.captures.sorted { $0.sortIndex > $1.sortIndex } }
    private var others: [Theme] { allThemes.filter { $0.id != theme.id } }

    var body: some View {
        List(selection: $selection) {
            ForEach(sorted, id: \.persistentModelID) { c in
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.text)
                    Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("이동") { moveTargets = [c]; moving = true }.tint(.blue)
                }
            }
            .onMove(perform: reorder)
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(theme.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if editMode.isEditing && !selection.isEmpty {
                    Button("이동 (\(selection.count))") {
                        moveTargets = sorted.filter { selection.contains($0.persistentModelID) }
                        moving = true
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { newName = theme.name; renaming = true } label: { Label("이름 변경", systemImage: "pencil") }
                    if !others.isEmpty {
                        Button { merging = true } label: { Label("다른 주제로 합치기", systemImage: "arrow.triangle.merge") }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
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
            ForEach(others) { target in Button(target.name) { mergeInto(target) } }
        }
        .confirmationDialog("이 기록을 어디로 옮길까요?", isPresented: $moving, titleVisibility: .visible) {
            ForEach(others) { target in
                Button(target.name) { Curation.move(moveTargets, to: target, context: context); finishMove() }
            }
            Button("새 주제로 추출") { Curation.extractToNew(moveTargets, context: context); finishMove() }
        }
    }

    private func finishMove() {
        moveTargets = []
        selection.removeAll()
        editMode = .inactive
        if theme.captures.isEmpty { dismiss() }
    }

    private func reorder(from: IndexSet, to: Int) {
        var arr = sorted
        arr.move(fromOffsets: from, toOffset: to)
        let n = arr.count
        for (i, c) in arr.enumerated() { c.sortIndex = Double(n - i) }   // 위가 큰 값
        try? context.save()
    }

    private func mergeInto(_ target: Theme) {
        Curation.move(Array(theme.captures), to: target, context: context)
        dismiss()
    }
}
