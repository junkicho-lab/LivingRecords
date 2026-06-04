import SwiftUI
import SwiftData

// S1/S2/S4 — 기록 목록. 봉인·에너지·주제 표시 + 스와이프 이동(재배치).
struct CaptureListView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]
    @Query(sort: \Theme.createdAt) private var themes: [Theme]

    var body: some View {
        NavigationStack {
            List {
                Section {
                ForEach(captures) { c in
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
                } header: {
                    Text("기록을 길게 눌러 다른 주제로 옮길 수 있어요. (좌우로 쓸면 탭 이동)")
                        .textCase(nil)
                }
            }
            .navigationTitle("기록")
            .overlay {
                if captures.isEmpty {
                    ContentUnavailableView("아직 포착이 없어요", systemImage: "mic",
                                           description: Text("포착 탭에서 말하거나 입력해 보세요."))
                }
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
