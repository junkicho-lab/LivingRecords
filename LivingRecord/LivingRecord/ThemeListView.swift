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
    @State private var rising: Set<UUID> = []    // 이번 주 떠오르는 주제(흐름 신호, onAppear 1회 계산)
    @State private var cooling: Set<UUID> = []   // 식어가는 주제

    var body: some View {
        NavigationStack {
            List {
                ForEach(themes) { t in
                    NavigationLink {
                        ThemeDetailView(theme: t)
                    } label: {
                        themeRow(t)
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
            }
            .navigationTitle("주제")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadSignals() }
            .safeAreaInset(edge: .top) {
                Text("길게 눌러 이름 변경·합치기 · 좌우로 쓸어 탭 이동")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 6).background(.bar)
            }
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

    // 시안: 상태 점 + 이름 + 맥락 한 줄 + 개수 배지.
    @ViewBuilder
    private func themeRow(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Circle().fill(stateColor(t)).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(t.name).font(.callout.weight(.medium)).lineLimit(1)
                Text(contextLine(t)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Text("\(t.captures.count)")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 10).padding(.vertical, 2)
                .background(Color.gray.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    // 상태 점: 식어감=회색, 떠오름·활성=초록, 맴돎=주황, 결정됨=회색.
    private func stateColor(_ t: Theme) -> Color {
        if cooling.contains(t.id) { return .gray }
        if rising.contains(t.id) { return .green }
        switch t.state {
        case .active:  return .green
        case .looping: return .orange
        case .cooling: return .gray
        case .decided: return .secondary
        }
    }

    // 맥락 한 줄: 최근 날짜 + 흐름 신호(떠오르는 중 / 식어감).
    private func contextLine(_ t: Theme) -> String {
        guard let last = t.captures.map({ $0.createdAt }).max() else { return "비어 있음" }
        var s = "최근 \(last.formatted(.dateTime.month().day()))"
        if rising.contains(t.id) { s += " · 떠오르는 중" }
        else if cooling.contains(t.id) { s += " · 식어감" }
        return s
    }

    private func loadSignals() {
        rising = Set(WeeklyReview.candidates(context: context, now: .now)
            .filter { $0.trend == .rising }.map { $0.theme.id })
        cooling = Set(WeeklyReview.coolingThemes(context: context, now: .now).map { $0.theme.id })
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
    @State private var editTarget: Capture?     // 내용 수정 대상(음성 오탈자 교정)
    @State private var editText = ""
    @State private var pendingDelete: Capture?  // 삭제 확인 대상

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
                        Button { editTarget = c; editText = c.text } label: {
                            Label("내용 수정", systemImage: "square.and.pencil")
                        }
                        Button(role: .destructive) { pendingDelete = c } label: {
                            Label("기록 삭제", systemImage: "trash")
                        }
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
                Text("기록을 길게 눌러 내용 수정·다른 주제로 이동 (좌우로 쓸면 탭 이동)")
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
        .sheet(item: $editTarget) { c in
            NavigationStack {
                Form {
                    Section {
                        TextField("내용", text: $editText, axis: .vertical)
                            .lineLimit(3...14)
                    } footer: {
                        Text("음성 인식 오탈자를 고칠 수 있어요. 저장하면 검색·미러도 함께 갱신됩니다. (주제는 그대로 유지)")
                    }
                }
                .navigationTitle("내용 수정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("취소") { editTarget = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") { saveEdit(c) }
                            .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("이 기록을 삭제할까요?",
                            isPresented: Binding(get: { pendingDelete != nil },
                                                 set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible, presenting: pendingDelete) { c in
            Button("삭제", role: .destructive) { deleteCapture(c) }
            Button("취소", role: .cancel) {}
        }
    }

    private func dismissIfEmpty() {
        if theme.captures.isEmpty { dismiss() }
    }

    // 기록 삭제. 미러 .md 제거 + 빈 주제면 주제·허브까지 정리하고 화면 닫기.
    private func deleteCapture(_ c: Capture) {
        ObsidianMirrorImpl(store: vault).delete(c)   // 미러 .md 제거(봉인 폴더 포함)
        context.delete(c)
        try? context.save()
        if theme.captures.isEmpty {                  // 마지막 기록까지 지움 → 주제 정리 후 닫기
            let name = theme.name
            context.delete(theme)
            try? context.save()
            WikiBuilder.deleteTheme(named: name, vault: vault)
            WikiBuilder.updateIndex(context: context, vault: vault)
            dismiss()
        } else {
            WikiBuilder.updateTheme(theme, context: context, vault: vault)   // 허브에서 그 줄 제거
            WikiBuilder.updateIndex(context: context, vault: vault)
        }
    }

    // 원문 수정(오탈자 교정). 텍스트만 바꾸고 주제는 유지. 임베딩·미러·허브 스니펫을 갱신.
    private func saveEdit(_ c: Capture) {
        let t = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        editTarget = nil
        guard !t.isEmpty, t != c.text else { return }
        c.text = t
        c.embedding = EmbedderImpl.shared.embed(t)   // 텍스트 바뀌면 임베딩도 갱신(검색·메아리 일관)
        try? context.save()
        ObsidianMirrorImpl(store: vault).remirror([c])                  // 미러 .md 갱신(봉인 폴더 포함)
        WikiBuilder.updateTheme(theme, context: context, vault: vault)  // 허브 스니펫 갱신
    }

    private func mergeInto(_ target: Theme) {
        Curation.move(Array(theme.captures), to: target, context: context, vault: vault)
        dismiss()
    }
}
