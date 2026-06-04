import SwiftUI
import SwiftData

// S7 — 기간 정리. 구간 선택 + 생성.
struct PeriodReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Environment(CloudConsent.self) private var consent
    @State private var rangeSel = 0     // 0:30일 1:90일 2:전체
    @State private var generating = false
    @State private var digest: Digest?

    private var days: Int? { [30, 90, nil][rangeSel] }

    var body: some View {
        List {
            Section {
                Picker("기간", selection: $rangeSel) {
                    Text("최근 30일").tag(0); Text("최근 90일").tag(1); Text("전체").tag(2)
                }
                .pickerStyle(.segmented)
                Button {
                    Task {
                        generating = true
                        digest = await PeriodReview.build(days: days, context: context, vault: vault, consent: consent, now: Date())
                        generating = false
                    }
                } label: {
                    if generating { ProgressView() } else { Label("기간 정리 생성", systemImage: "sparkles") }
                }
                .disabled(generating)
            } footer: {
                Text("선택 구간의 반복 주제와 내린 결정을 모아 큰 흐름을 정리합니다. 클라우드가 켜져 있으면 더 깊게 종합해요.")
            }

            if let d = digest {
                Section {
                    Text((try? AttributedString(markdown: d.narrative,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(d.narrative))
                }
            }
        }
        .navigationTitle("기간 정리")
    }
}
