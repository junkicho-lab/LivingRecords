import SwiftUI
import SwiftData

// S4 — 주제 탭. 통합된 주제별 포착 + 큐레이션(이름변경/합치기) + 기록 재배치(이동/다중이동/순서).
struct ThemeListView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Theme.createdAt, order: .reverse) private var themes: [Theme]
    @State private var renameTarget: Theme?
    @State private var newName = ""
    @State private var renaming = false
    @State private var mergeSource: Theme?
    @State private var merging = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(themes) { t in
                        NavigationLink {
                            ThemeDetailView(theme: t)
                        } label: {
                            HStack {
                                Text(t.name).lineLimit(1)
                                Spacer()
                                Text("\(t.captures.count)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .contextMenu {
                            Button { renameTarget = t; newName = t.name; renaming = true } label: {
                                Label("이름 변경", systemImage: "pencil")
                            }
                            if themes.count > 1 {
                                Button { mergeSource = t; merging = true } label: {
                                    Label("다른 주제로 합치기", systemImage: "arrow.triangle.merge")
                                }
                            }
                        }
                    }
                } header: {
                    Text("주제를 길게 눌러 이름 변경·합치기 (좌우로 쓸면 탭 이동)")
                        .textCase(nil)
                }
            }
            .navigationTitle("주제")
            .overlay {
                if themes.isEmpty {
                    ContentUnavailableView("아직 주제가 없어요", systemImage: "circle.grid.cross",
                                           description: Text("포착이 쌓이면 비슷한 생각이 주제로 묶여요."))
                }
            }
            .alert("주제 이름 변경", isPresented: $renaming) {
                TextField("이름", text: $newName)
                Button("저장") {
                    if let t = renameTarget {
                        let old = t.name
                        let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !n.isEmpty && n != old {
                            t.name = n; try? context.save()
                            ObsidianMirrorImpl(store: vault).remirror(Array(t.captures))
                            WikiBuilder.deleteTheme(named: old, vault: vault)   // 옛 허브 제거 → 새 이름으로
                            WikiBuilder.updateTheme(t, context: context, vault: vault)
                            WikiBuilder.updateIndex(context: context, vault: vault)
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            }
            .confirmationDialog("어느 주제로 합칠까요?", isPresented: $merging, titleVisibility: .visible) {
                ForEach(themes.filter { $0.id != mergeSource?.id }) { target in
                    Button(target.name) {
                        if let s = mergeSource {
                            Curation.move(Array(s.captures), to: target, context: context, vault: vault)
                        }
                    }
                }
            }
        }
    }
}

struct ThemeDetailView: View {
    let theme: Theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Theme.createdAt) private var allThemes: [Theme]
    @State private var renaming = false
    @State private var newName = ""
    @State private var merging = false

    private var sorted: [Capture] { theme.captures.sorted { $0.sortIndex > $1.sortIndex } }
    private var others: [Theme] { allThemes.filter { $0.id != theme.id } }

    var body: some View {
        List {
            Section {
                ForEach(sorted, id: \.persistentModelID) { c in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.text)
                        Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Section("다른 주제로 이동") {
                            ForEach(others) { t in
                                Button(t.name) { Curation.move([c], to: t, context: context, vault: vault); dismissIfEmpty() }
                            }
                            Button { Curation.extractToNew([c], context: context, vault: vault); dismissIfEmpty() } label: {
                                Label("새 주제로 추출", systemImage: "plus.circle")
                            }
                        }
                    }
                }
            } header: {
                Text("기록을 길게 눌러 다른 주제로 이동 (좌우로 쓸면 탭 이동)")
                    .textCase(nil)
            }
        }
        .navigationTitle(theme.name)
        .toolbar {
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
                let old = theme.name
                let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !n.isEmpty && n != old {
                    theme.name = n; try? context.save()
                    ObsidianMirrorImpl(store: vault).remirror(Array(theme.captures))   // 링크 이름 갱신
                    WikiBuilder.deleteTheme(named: old, vault: vault)
                    WikiBuilder.updateTheme(theme, context: context, vault: vault)
                    WikiBuilder.updateIndex(context: context, vault: vault)
                }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("어느 주제로 합칠까요?", isPresented: $merging, titleVisibility: .visible) {
            ForEach(others) { target in Button(target.name) { mergeInto(target) } }
        }
    }

    private func dismissIfEmpty() {
        if theme.captures.isEmpty { dismiss() }
    }

    private func mergeInto(_ target: Theme) {
        Curation.move(Array(theme.captures), to: target, context: context, vault: vault)
        dismiss()
    }
}
