import SwiftUI
import SwiftData

// S6a — 주간 회고: 지속 후보 + 결정[지속/보류/접기] + 주간 서술.
struct WeeklyReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Environment(CloudConsent.self) private var consent
    @State private var cands: [Candidate] = []
    @State private var generating = false
    @State private var weekly: Digest?
    @State private var related: [(String, String)] = []

    var body: some View {
        List {
            Section {
                if cands.isEmpty {
                    Text("이번 주 두 번 이상 돌아온 주제가 아직 없어요.")
                        .foregroundStyle(.secondary)
                }
                ForEach(cands) { c in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(c.theme.name).font(.headline)
                            Spacer()
                            trendTag(c.trend)
                            if c.evolving == true { tag("🌱 진화", .green) }
                            else if c.evolving == false { tag("🔁 맴돎", .orange) }
                        }
                        Text("\(c.days)일 · \(c.count)회"
                             + (c.avgEnergy.map { String(format: " · 에너지 %.0f%%", $0 * 100) } ?? "")
                             + energyTrendText(c.energyTrend))
                            .font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            decideButton("지속", .sustain, c, .green)
                            decideButton("보류", .hold, c, .gray)
                            decideButton("접기", .drop, c, .red)
                        }
                        if let v = c.latestVerdict {
                            Text("결정: \(verdictLabel(v))").font(.caption2).foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("지속 후보 — 무엇을 이어갈까요?")
            } footer: {
                Text("↑ 떠오름·↓ 식어감은 최근 흐름, 🌱 진화·🔁 맴돎은 생각이 옮겨갔는지예요. 떠오르는 주제는 지속을, 식어가는 주제는 놓아줄지 가늠해 보세요.")
            }

            if !related.isEmpty {
                Section {
                    ForEach(related.indices, id: \.self) { i in
                        Label("\(related[i].0)  ↔  \(related[i].1)", systemImage: "link")
                    }
                } header: {
                    Text("연결된 주제 (관련 있어 보임)")
                } footer: {
                    Text("서로 가까운 주제예요. 한 줄기일 수도, 합칠 만할 수도 있어요. (추정 — 참고용)")
                }
            }

            Section("주간 서술") {
                Button {
                    Task {
                        generating = true
                        weekly = await WeeklyReview.buildDigest(context: context, vault: vault, consent: consent, now: Date())
                        generating = false
                    }
                } label: {
                    if generating { ProgressView() } else { Label("주간 정리 생성", systemImage: "sparkles") }
                }
                .disabled(generating)
                if let w = weekly {
                    Text((try? AttributedString(markdown: w.narrative,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(w.narrative))
                }
            }
        }
        .navigationTitle("주간 회고")
        .onAppear { refresh() }
    }

    private func refresh() {
        cands = WeeklyReview.candidates(context: context, now: Date())
        related = WeeklyReview.relatedPairs(cands)
    }

    private func decideButton(_ title: String, _ v: Verdict, _ c: Candidate, _ color: Color) -> some View {
        Button(title) {
            WeeklyReview.decide(c.theme, v, context: context)
            refresh()
        }
        .font(.caption).buttonStyle(.bordered).tint(color)
    }

    @ViewBuilder
    private func trendTag(_ t: Candidate.Trend) -> some View {
        switch t {
        case .rising:  tag("↑ 떠오름", .blue)
        case .cooling: tag("↓ 식어감", .gray)
        case .steady:  EmptyView()
        }
    }

    // 에너지 추세를 캡션에 덧붙임(↑ 오름 / ↓ 식음). 보류(nil)나 미미하면 표시 안 함.
    private func energyTrendText(_ trend: Double?) -> String {
        guard let t = trend else { return "" }
        if t > 0.05 { return " · 열 ↑" }
        if t < -0.05 { return " · 열 ↓" }
        return ""
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text).font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule()).foregroundStyle(color)
    }

    private func verdictLabel(_ v: Verdict) -> String {
        switch v { case .sustain: "지속"; case .hold: "보류"; case .drop: "접기" }
    }
}
