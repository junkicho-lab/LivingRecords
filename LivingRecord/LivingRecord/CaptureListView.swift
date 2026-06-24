import SwiftUI
import SwiftData

// S1/S2/S4 — 기록 목록. 봉인·에너지·주제 표시 + 스와이프 이동(재배치).
// v4 — 검색: 전문(정확 포함, 라이브) 주력 + 의미('비슷한 기록', 검색 실행 시) 보조. (스파이크 ⑧)
struct CaptureListView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]
    @Query(sort: \Theme.createdAt) private var themes: [Theme]
    @State private var query = ""
    @State private var semanticHits: [Capture] = []
    @State private var range = DateRange()
    @State private var editTarget: Capture?     // 내용 수정 대상(음성 오탈자 교정)
    @State private var editText = ""
    @State private var pendingDelete: Capture?  // 삭제 확인 대상

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var browse: [Capture] { captures.filter { range.contains($0.createdAt) } }   // 기간 필터(검색 아닐 때)

    // 전문 검색(정확 포함, 공백/대소문자 무시).
    private var textMatches: [Capture] {
        guard !trimmed.isEmpty else { return [] }
        return captures.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List {
                if trimmed.isEmpty {
                    ForEach(browse) { row($0) }
                } else {
                    if !textMatches.isEmpty {
                        Section("정확히 포함 (\(textMatches.count))") {
                            ForEach(textMatches) { row($0) }
                        }
                    }
                    let semanticOnly = semanticHits.filter { hit in !textMatches.contains { $0.id == hit.id } }
                    if !semanticOnly.isEmpty {
                        Section {
                            ForEach(semanticOnly) { row($0) }
                        } header: {
                            Text("비슷한 기록 (추정)")
                        } footer: {
                            Text("뜻이 가까워 보이는 기록이에요. 정확한 단어가 없어도 찾아줘요. (추정 — 참고용)")
                        }
                    }
                }
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                if trimmed.isEmpty {     // 검색 중엔 칩 숨김(검색은 전체에서)
                    VStack(spacing: 4) {
                        DateFilterBar(range: $range)
                        Text(range.kind == .all ? "길게 눌러 옮기기 · 좌우로 쓸어 탭 이동"
                                                 : "\(range.kind.rawValue) · \(browse.count)개")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 6)
                    .background(.bar)
                }
            }
            .searchable(text: $query, prompt: "기록 검색 (단어 또는 뜻)")
            .onSubmit(of: .search) { runSemantic() }
            .onChange(of: query) { _, _ in if trimmed.isEmpty { semanticHits = [] } }
            .overlay {
                if captures.isEmpty {
                    ContentUnavailableView("아직 포착이 없어요", systemImage: "mic",
                                           description: Text("포착 탭에서 말하거나 입력해 보세요."))
                } else if trimmed.isEmpty && browse.isEmpty {
                    ContentUnavailableView("이 기간엔 기록이 없어요", systemImage: "calendar",
                                           description: Text("다른 기간 칩을 골라 보세요."))
                } else if !trimmed.isEmpty && textMatches.isEmpty && semanticHits.isEmpty {
                    ContentUnavailableView("결과 없음", systemImage: "magnifyingglass",
                                           description: Text("리턴을 눌러 비슷한 뜻으로도 찾아볼 수 있어요."))
                }
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
        if let theme = c.theme { WikiBuilder.updateTheme(theme, context: context, vault: vault) }   // 허브 스니펫 갱신
    }

    // 검색 실행 시에만 의미 검색(매 타자마다 임베딩하지 않음).
    private func runSemantic() {
        semanticHits = SemanticSearch.similar(to: trimmed, in: captures)
    }

    @ViewBuilder
    private func row(_ c: Capture) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                if c.sealed {
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.purple)
                }
                Text(c.text)
            }
            HStack(spacing: 10) {
                Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
                if let e = c.energy { energyBar(e) }
                if let name = c.theme?.name {
                    Text(name)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button { editTarget = c; editText = c.text } label: {
                Label("내용 수정", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) { pendingDelete = c } label: {
                Label("기록 삭제", systemImage: "trash")
            }
            Section("다른 주제로 옮기기") {
                ForEach(themes.filter { $0.id != c.theme?.id }) { t in
                    Button(t.name) { Curation.move([c], to: t, context: context, vault: vault) }
                }
                Button { Curation.extractToNew([c], context: context, vault: vault) } label: {
                    Label("새 주제로 추출", systemImage: "plus.circle")
                }
            }
        }
    }

    private func deleteCapture(_ c: Capture) {
        let host = c.theme
        ObsidianMirrorImpl(store: vault).delete(c)          // 미러 .md 제거
        context.delete(c)
        try? context.save()
        if let host {
            if host.captures.isEmpty {                      // 빈 주제 정리 + 허브 삭제
                let name = host.name
                context.delete(host); try? context.save()
                WikiBuilder.deleteTheme(named: name, vault: vault)
            } else {
                WikiBuilder.updateTheme(host, context: context, vault: vault)   // 허브에서 그 줄 제거
            }
            WikiBuilder.updateIndex(context: context, vault: vault)
        }
    }

    @ViewBuilder
    private func energyBar(_ e: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "waveform").font(.caption2)
            Capsule().fill(Color.orange.opacity(0.25)).frame(width: 44, height: 4)
                .overlay(alignment: .leading) {
                    Capsule().fill(.orange).frame(width: 44 * e, height: 4)
                }
        }
        .foregroundStyle(.orange)
    }
}
