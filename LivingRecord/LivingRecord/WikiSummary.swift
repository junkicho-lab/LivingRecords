import Foundation
import SwiftData

// LLM wiki 슬라이스 B — 주제 허브 '## 한눈에'를 클라우드(Claude)로 종합. 명시적 갱신만(비용).
// 2단계 증류: 원문은 로컬에서 추상화(LocalSynth) → 증류층만 클라우드행. 봉인 제외. 전송 로그 남김.
enum WikiSummary {
    static let hubSystem = "너는 한 주제의 핵심을 한눈에 보여주는 도우미다. 주어진 주제 요약을 보고, 이 주제가 무엇에 관한 것이고 어디로 향하는지 한국어 2~4문장으로 담백하게 정리하라. 군더더기·과장 없이, 단정적 평가는 피하라."

    @MainActor
    static func refresh(context: ModelContext, vault: VaultStore, consent: CloudConsent) async -> String {
        guard vault.vaultURL != nil else { return "볼트를 먼저 연결하세요." }
        guard consent.canSendToCloud, let key = consent.apiKey else { return "클라우드 깊은 종합을 켜고 API 키를 저장하세요." }

        let themes = ((try? context.fetch(FetchDescriptor<Theme>())) ?? [])
            .filter { !$0.captures.filter { !$0.sealed }.isEmpty }
        var ok = 0, fail = 0
        for t in themes {
            let distilled = await distillTheme(t)        // 로컬 추상화(원문 X)
            do {
                let r = try await CloudSynthesizer.synthesize(distilled: distilled, apiKey: key, system: hubSystem)
                if !r.isEmpty {
                    t.summary = r
                    context.insert(Transmission(kind: "wiki", charCount: distilled.count))   // 전송 로그
                    ok += 1
                } else { fail += 1 }
            } catch { fail += 1 }
            WikiBuilder.updateTheme(t, context: context, vault: vault)   // 허브에 한눈에 반영
        }
        try? context.save()
        WikiBuilder.updateIndex(context: context, vault: vault)
        return "AI 종합 갱신 — \(ok)개 완료" + (fail > 0 ? ", \(fail)개 실패" : "") + "."
    }

    // 한 주제를 로컬에서 추상화(요약). FM 막히면 개수만 — 원문은 절대 클라우드로 안 보냄.
    @MainActor
    static func distillTheme(_ theme: Theme) async -> String {
        let caps = theme.captures.filter { !$0.sealed }
        let texts = caps.map { $0.text }
        let summary = await LocalSynth.generate(
            "다음 같은 주제의 메모들을 2~3문장으로 요약하라. 구체적 흐름·변화 중심. 원문 인용 말고 추상적으로.",
            texts.joined(separator: "\n")) ?? "\(texts.count)개의 생각"
        return "주제 '\(theme.name)' (\(caps.count)개 메모):\n\(summary)"
    }
}
