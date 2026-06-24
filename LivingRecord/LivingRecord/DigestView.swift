import SwiftUI
import SwiftData

// S5 — 정리 탭. 일일 정리 목록 + 오늘 정리 생성.
struct DigestListView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Digest.createdAt, order: .reverse) private var digests: [Digest]
    @State private var building = false
    @State private var showWeekly = false
    @State private var showPeriod = false
    @State private var writingNote = false      // 내 생각 쓰기(사용자 노트)
    @State private var range = DateRange()

    private var filtered: [Digest] { digests.filter { range.contains($0.createdAt) } }   // 만든 시점 기준 기간 필터

    var body: some View {
        NavigationStack {
            List(filtered) { d in
                NavigationLink {
                    DigestDetailView(digest: d)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: kindIcon(d.kind)).font(.title3)
                            .foregroundStyle(d.kind == .note ? Color.secondary : Color.blue).frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kindLabel(d.kind)).font(.callout.weight(.medium))
                            Text(subtitle(d)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { deleteDigest(d) } label: { Label("삭제", systemImage: "trash") }
                }
            }
            .navigationTitle("정리")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) { DateFilterBar(range: $range).padding(.bottom, 4).background(.bar) }
            .overlay {
                if digests.isEmpty {
                    ContentUnavailableView("아직 정리가 없어요", systemImage: "doc.text",
                                           description: Text("오늘 포착을 모아 일일 정리를 만들어요."))
                } else if filtered.isEmpty {
                    ContentUnavailableView("이 기간엔 정리가 없어요", systemImage: "calendar",
                                           description: Text("다른 기간 칩을 골라 보세요."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { writingNote = true } label: { Label("내 생각 쓰기", systemImage: "square.and.pencil") }
                        Divider()
                        Button {
                            Task {
                                building = true
                                _ = await DailyDigest.build(for: Date(), context: context, vault: vault)
                                building = false
                            }
                        } label: { Label("일일 정리 (오늘)", systemImage: "calendar") }
                        Button { showWeekly = true } label: { Label("주간 회고", systemImage: "calendar.badge.clock") }
                        Button { showPeriod = true } label: { Label("기간 정리", systemImage: "calendar.badge.exclamationmark") }
                    } label: {
                        if building { ProgressView() } else { Label("정리 만들기", systemImage: "plus.circle") }
                    }
                }
            }
            .sheet(isPresented: $showWeekly) {
                NavigationStack {
                    WeeklyReviewView()
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("완료") { showWeekly = false } } }
                }
            }
            .sheet(isPresented: $showPeriod) {
                NavigationStack {
                    PeriodReviewView()
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("완료") { showPeriod = false } } }
                }
            }
            .sheet(isPresented: $writingNote) {
                DigestEditorView(title: "내 생각", text: "") { saveNote($0) }
            }
        }
    }

    // 정리 삭제. 미러 .md도 제거.
    private func deleteDigest(_ d: Digest) {
        ObsidianMirrorImpl(store: vault).delete(d)
        context.delete(d)
        try? context.save()
    }

    // 사용자가 직접 쓴 생각을 정리(note)로 저장. 봉인 아님 → Digests/로 미러.
    private func saveNote(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let now = Date()
        let d = Digest(kind: .note, periodStart: now, periodEnd: now, narrative: t, generatedInCloud: false)
        context.insert(d)
        try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(d)
    }

    private func kindLabel(_ k: DigestKind) -> String {
        switch k { case .daily: "일일 정리"; case .weekly: "주간 정리"; case .period: "기간 정리"; case .note: "내 생각" }
    }
    private func kindIcon(_ k: DigestKind) -> String {
        switch k {
        case .daily:  "calendar"
        case .weekly: "calendar.badge.clock"
        case .period: "calendar.badge.exclamationmark"
        case .note:   "square.and.pencil"
        }
    }

    // 날짜(기간형은 범위) + 서술 첫 줄 미리보기.
    private func subtitle(_ d: Digest) -> String {
        let date: String
        switch d.kind {
        case .weekly, .period:
            date = "\(d.periodStart.formatted(.dateTime.month().day())) ~ \(d.periodEnd.formatted(.dateTime.month().day()))"
        case .daily, .note:
            date = d.periodStart.formatted(.dateTime.month().day())
        }
        let p = preview(d.narrative)
        return p.isEmpty ? date : "\(date) · \(p)"
    }
    // 마크다운 제목·표식·빈 줄을 건너뛴 첫 '내용' 줄.
    private func preview(_ narrative: String) -> String {
        for raw in narrative.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("**")
                || line.hasPrefix("-") || line.hasPrefix("☁️") || line.hasPrefix("_") { continue }
            return line
        }
        return ""
    }
}

struct DigestDetailView: View {
    let digest: Digest
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("정리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editing = true } label: { Label("수정", systemImage: "square.and.pencil") }
                    Button(role: .destructive) { confirmingDelete = true } label: { Label("삭제", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $editing) {
            DigestEditorView(title: "정리 수정", text: digest.narrative) { saveEdit($0) }
        }
        .confirmationDialog("이 정리를 삭제할까요?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) { deleteDigest() }
            Button("취소", role: .cancel) {}
        }
    }

    // 정리본은 마크다운(제목·불릿·굵게)이다. Text 하나로는 블록 표식이 그대로 보이므로 줄 단위로 렌더한다.
    private var content: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(digest.narrative.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
                lineView(raw)
            }
        }
    }

    @ViewBuilder
    private func lineView(_ raw: String) -> some View {
        let t = raw.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            Color.clear.frame(height: 3)
        } else if t.hasPrefix("### ") {
            Text(inline(String(t.dropFirst(4)))).font(.headline).padding(.top, 8)
        } else if t.hasPrefix("## ") {
            Text(inline(String(t.dropFirst(3)))).font(.title3.bold()).padding(.bottom, 2)
        } else if t.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(.secondary)
                Text(inline(String(t.dropFirst(2)))).frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text(inline(t)).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }

    // 정리 삭제. 미러 .md 제거 후 화면 닫기.
    private func deleteDigest() {
        ObsidianMirrorImpl(store: vault).delete(digest)
        context.delete(digest)
        try? context.save()
        dismiss()
    }

    // 정리 본문 수정. 종류·봉인 파생 여부는 유지하고 본문만 바꿔 다시 미러.
    private func saveEdit(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, t != digest.narrative else { return }
        digest.narrative = t
        try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(digest)   // 봉인 파생이면 봉인/ 유지(digest.sealedDerived)
    }
}

// 정리 작성·수정 공용 에디터(마크다운 자유 작성).
struct DigestEditorView: View {
    let title: String
    let onSave: (String) -> Void
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(title: String, text: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.onSave = onSave
        self._text = State(initialValue: text)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 260)
                } footer: {
                    Text("마크다운으로 자유롭게 쓸 수 있어요. 저장하면 볼트(Digests/)에도 미러됩니다.")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { onSave(text); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
