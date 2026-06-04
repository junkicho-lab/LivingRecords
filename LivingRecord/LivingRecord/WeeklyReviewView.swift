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

    var body: some View {
        List {
            Section {
                if cands.isEmpty {
                    Text("이번 주 두 번 이상 돌아온 주제가 아직 없어요.")
                        .foregroundStyle(.secondary)
                }
                ForEach(cands) { c in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(c.theme.name).font(.headline)
                            Spacer()
                            if c.evolving == true { tag("🌱 진화", .green) }
                            else if c.evolving == false { tag("🔁 맴돎", .orange) }
                        }
                        Text("\(c.days)일 · \(c.count)회"
                             + (c.avgEnergy.map { String(format: " · 에너지 %.0f%%", $0 * 100) } ?? ""))
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
                Text("자주 돌아오고 열이 오른 주제예요. 지속/보류/접기로 정하면 다음 회고에 반영됩니다.")
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

    private func refresh() { cands = WeeklyReview.candidates(context: context, now: Date()) }

    private func decideButton(_ title: String, _ v: Verdict, _ c: Candidate, _ color: Color) -> some View {
        Button(title) {
            WeeklyReview.decide(c.theme, v, context: context)
            refresh()
        }
        .font(.caption).buttonStyle(.bordered).tint(color)
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
