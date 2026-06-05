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
                    Section {
                        ForEach(browse) { row($0) }
                    } header: {
                        Text(range.kind == .all
                             ? "기록을 길게 눌러 다른 주제로 옮길 수 있어요. (좌우로 쓸면 탭 이동)"
                             : "\(range.kind.rawValue) · \(browse.count)개")
                            .textCase(nil)
                    }
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
            .navigationBarTitleDisplayMode(.inline)   // 큰 제목과 칩 바 겹침 방지
            .safeAreaInset(edge: .top) {
                if trimmed.isEmpty { DateFilterBar(range: $range) }   // 검색 중엔 칩 숨김(검색은 전체에서)
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
        }
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
            Section("다른 주제로 옮기기") {
                ForEach(themes.filter { $0.id != c.theme?.id }) { t in
                    Button(t.name) { Curation.move([c], to: t, context: context, vault: vault) }
                }
                Button { Curation.extractToNew([c], context: context, vault: vault) } label: {
                    Label("새 주제로 추출", systemImage: "plus.circle")
                }
            }
            Button(role: .destructive) { deleteCapture(c) } label: {
                Label("기록 삭제", systemImage: "trash")
            }
        }
    }

    private func deleteCapture(_ c: Capture) {
        let theme = c.theme
        ObsidianMirrorImpl(store: vault).delete(c)          // 미러 .md 제거
        context.delete(c)
        if let theme, theme.captures.isEmpty { context.delete(theme) }   // 빈 주제 정리
        try? context.save()
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
