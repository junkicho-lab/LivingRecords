import SwiftUI
import SwiftData

// 저녁 결정 드립의 도착지 — 알림을 탭하면 이 카드 하나가 뜬다. 거울/확인형: 묻기만 하고 사람이 정한다.
// [놓기]=drop, [아직 이어가기]=sustain. 무대응(나중에)=스누즈. 결정은 언제든 바뀐다.
struct DecisionCardView: View {
    let themeID: UUID
    let question: String
    let onDone: () -> Void
    @State private var isSubmitting = false   // 빠른 더블탭으로 Decision 중복 삽입 방지
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "leaf").font(.system(size: 40)).foregroundStyle(.green.opacity(0.7))
            Text(question)
                .font(.title3).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            Text("결정은 언제든 바꿀 수 있어요.").font(.caption).foregroundStyle(.secondary)
            Spacer()
            VStack(spacing: 12) {
                Button(role: .destructive) { act(.drop) } label: {
                    Label("놓기", systemImage: "wind").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
                Button { act(.sustain) } label: {
                    Label("아직 이어가기", systemImage: "flame").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSubmitting)
                Button("나중에") {
                    guard !isSubmitting else { return }
                    isSubmitting = true
                    EveningPrompt.snooze(themeID); onDone()
                }
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 4)
                    .disabled(isSubmitting)
            }
            .padding(.horizontal)
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func act(_ verdict: Verdict) {
        guard !isSubmitting else { return }
        isSubmitting = true
        if let theme = fetchTheme() {
            WeeklyReview.decide(theme, verdict, context: context)
            WikiBuilder.updateTheme(theme, context: context, vault: vault)   // 허브 결정 반영
            WikiBuilder.updateIndex(context: context, vault: vault)
        }
        EveningPrompt.snooze(themeID)   // 같은 항목 한동안 다시 안 물음
        onDone()
    }

    private func fetchTheme() -> Theme? {
        let id = themeID
        return (try? context.fetch(FetchDescriptor<Theme>(predicate: #Predicate { $0.id == id })))?.first
    }
}
