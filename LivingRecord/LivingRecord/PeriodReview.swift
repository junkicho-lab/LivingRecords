import Foundation
import SwiftData
import FoundationModels

// S7 — 기간 정리(기본형). 임의 구간 반복 주제 + 결정 로그 + 종합(클라우드 옵트인). 실행추적·연결·냉각은 post-v1.
enum PeriodReview {
    @MainActor
    static func build(days: Int?, context: ModelContext, vault: VaultStore, consent: CloudConsent, now: Date) async -> Digest? {
        let cal = Calendar.current
        let start = days.flatMap { cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: now)) }
            ?? Date(timeIntervalSince1970: 0)

        let all = (try? context.fetch(FetchDescriptor<Capture>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let caps = all.filter { $0.createdAt >= start && $0.createdAt < now }
        guard !caps.isEmpty else { return nil }

        // 주제별 반복
        var byTheme: [String: (days: Set<Date>, count: Int)] = [:]
        for c in caps {
            let n = c.theme?.name ?? "미분류"
            var e = byTheme[n] ?? (Set<Date>(), 0)
            e.days.insert(cal.startOfDay(for: c.createdAt)); e.count += 1
            byTheme[n] = e
        }
        let recurring = byTheme.filter { $0.value.count >= 2 }.sorted { $0.value.days.count > $1.value.days.count }

        // 결정 로그
        let decisions = (try? context.fetch(FetchDescriptor<Decision>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        let periodDecisions = decisions.filter { $0.createdAt >= start && $0.createdAt < now }

        var input = "기간 내 자주 돌아온 주제:\n"
        for (name, v) in recurring.prefix(10) { input += "- \(name): \(v.days.count)일·\(v.count)회\n" }
        if !periodDecisions.isEmpty {
            input += "내린 결정:\n"
            for d in periodDecisions.prefix(10) { input += "- \(d.theme?.name ?? "?"): \(verdictLabel(d.verdict))\n" }
        }

        var cloud = false; var narr: String?
        if consent.canSendToCloud, let key = consent.apiKey {
            let distilled = await Distillation.distill(from: start, to: now, context: context)
            if let r = try? await CloudSynthesizer.synthesize(distilled: distilled + "\n" + input, apiKey: key), !r.isEmpty {
                narr = r; cloud = true
                context.insert(Transmission(kind: "period", charCount: (distilled + input).count))
            }
        }
        if narr == nil {
            let style = Templates.activeDirective(context: context)
            narr = await synth("너는 긴 호흡의 회고 도우미다. 아래 기간의 반복 주제와 내린 결정을 보고, 무엇이 꾸준히 이어졌고 무엇을 지속/접기로 정했는지 큰 흐름을 한국어로 짚어라. 단순 나열 금지. 스타일: \(style)", input)
        }

        let df = DateFormatter(); df.dateFormat = "yyyy.M.d"; df.locale = Locale(identifier: "ko_KR")
        var md = "## 기간 정리 (\(days.map { "최근 \($0)일" } ?? "전체"))\n\n"
        if cloud { md += "☁️ 깊은 종합(클라우드)\n\n" }
        md += (narr ?? "이 기간엔 \(recurring.prefix(3).map { $0.key }.joined(separator: ", ")) 같은 주제가 이어졌어요.") + "\n\n"
        md += "**자주 돌아온 주제**\n"
        for (name, v) in recurring.prefix(10) { md += "- \(name) — \(v.days.count)일·\(v.count)회\n" }
        if !periodDecisions.isEmpty {
            md += "\n**내린 결정과 그 이후**\n"
            for d in periodDecisions.prefix(20) {
                let after = d.theme?.captures.filter { $0.createdAt > d.createdAt }.count ?? 0
                let mark: String   // 결정 이후 그 주제가 어떻게 됐나(누적 피드백)
                switch d.verdict {
                case .sustain: mark = after > 0 ? " — 이어짐 ✓" : " — 조용해짐"
                case .drop:    mark = after > 0 ? " — 다시 올라옴 ↑" : " — 정리됨"
                case .hold:    mark = after > 0 ? " — \(after)회 더" : ""
                }
                md += "- \(d.theme?.name ?? "?") → \(verdictLabel(d.verdict)) (\(df.string(from: d.createdAt)))\(mark)\n"
            }
        }

        let dg = Digest(kind: .period, periodStart: start, periodEnd: now, narrative: md, generatedInCloud: cloud)
        context.insert(dg); try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(dg)
        return dg
    }

    static func verdictLabel(_ v: Verdict) -> String {
        switch v { case .sustain: "지속"; case .hold: "보류"; case .drop: "접기" }
    }

    private static func synth(_ instruction: String, _ input: String) async -> String? {
        await LocalSynth.generate(instruction, input)   // FM→MLX 폴백
    }
}
