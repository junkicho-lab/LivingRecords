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

    var body: some View {
        NavigationStack {
            List(digests) { d in
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
            .overlay {
                if digests.isEmpty {
                    ContentUnavailableView("아직 정리가 없어요", systemImage: "doc.text",
                                           description: Text("오늘 포착을 모아 일일 정리를 만들어요."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
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
        }
    }

    private func kindLabel(_ k: DigestKind) -> String {
        switch k { case .daily: "일일 정리"; case .weekly: "주간 정리"; case .period: "기간 정리" }
    }
}

struct DigestDetailView: View {
    let digest: Digest

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("정리")
    }

    private var content: some View {
        let attr = (try? AttributedString(
            markdown: digest.narrative,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(digest.narrative)
        return Text(attr)
    }
}
