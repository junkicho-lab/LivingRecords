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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kindLabel(d.kind)).font(.headline)
                        Text(d.periodStart, format: .dateTime.year().month().day())
                            .font(.caption).foregroundStyle(.secondary)
                    }
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
}

struct DigestDetailView: View {
    let digest: Digest
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @State private var editing = false

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("정리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Label("수정", systemImage: "square.and.pencil") }
            }
        }
        .sheet(isPresented: $editing) {
            DigestEditorView(title: "정리 수정", text: digest.narrative) { saveEdit($0) }
        }
    }

    private var content: some View {
        let attr = (try? AttributedString(
            markdown: digest.narrative,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(digest.narrative)
        return Text(attr)
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
    @State var text: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

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
