import Foundation
import SwiftData
import FoundationModels

// S6a — 주간 회고. 지속 후보(반복·에너지·진화/맴돎) + 결정. 주간 서술(로컬).
struct Candidate: Identifiable {
    let theme: Theme
    let days: Int            // 기간 내 활동한 distinct 일수
    let count: Int
    let avgEnergy: Double?
    let evolving: Bool?      // 임베딩 다양성: true=진화, false=맴돎, nil=판단보류
    let latestVerdict: Verdict?
    var id: PersistentIdentifier { theme.persistentModelID }
}

enum WeeklyReview {
    static let windowDays = 7

    // 지속 후보(결정적): 기간 내 2회 이상 등장한 주제. 반복도·에너지·진화여부.
    @MainActor
    static func candidates(context: ModelContext, now: Date) -> [Candidate] {
        let cal = Calendar.current
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now)) else { return [] }
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        // 주제별 최신 결정
        let decisions = (try? context.fetch(FetchDescriptor<Decision>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        var latestByTheme: [PersistentIdentifier: Verdict] = [:]
        for d in decisions { if let t = d.theme { latestByTheme[t.persistentModelID] = d.verdict } }

        var out: [Candidate] = []
        for t in themes {
            let caps = t.captures.filter { $0.createdAt >= windowStart }
            guard caps.count >= 2 else { continue }
            let verdict = latestByTheme[t.persistentModelID]
            if verdict == .drop { continue }   // 접은 주제는 후보에서 제외
            let days = Set(caps.map { cal.startOfDay(for: $0.createdAt) }).count
            let es = caps.compactMap { $0.energy }
            let avgE = es.isEmpty ? nil : es.reduce(0,+)/Double(es.count)
            out.append(Candidate(theme: t, days: days, count: caps.count,
                                 avgEnergy: avgE, evolving: diversity(caps), latestVerdict: verdict))
        }
        // 반복도(일수) → 개수 → 에너지 순
        return out.sorted {
            ($0.days, $0.count, $0.avgEnergy ?? 0) > ($1.days, $1.count, $1.avgEnergy ?? 0)
        }
    }

    // 임베딩 다양성으로 진화/맴돎 추정(저장된 임베딩 재사용). 거리 클수록 진화.
    private static func diversity(_ caps: [Capture]) -> Bool? {
        let vs = caps.compactMap { $0.embedding }
        guard vs.count >= 2 else { return nil }
        func cos(_ a: [Double], _ b: [Double]) -> Double {
            var d = 0.0, na = 0.0, nb = 0.0
            for i in 0..<min(a.count, b.count) { d += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
            return d / (na.squareRoot()*nb.squareRoot() + 1e-9)
        }
        var dist = 0.0, n = 0
        for i in 0..<vs.count { for j in (i+1)..<vs.count { dist += 1 - cos(vs[i], vs[j]); n += 1 } }
        guard n > 0 else { return nil }
        return (dist/Double(n)) > 0.18   // 임계값(러프). 다양 → 진화
    }

    @MainActor
    static func decide(_ theme: Theme, _ verdict: Verdict, context: ModelContext) {
        let d = Decision(theme: theme, verdict: verdict)
        context.insert(d)
        theme.state = (verdict == .drop) ? .decided : .active
        try? context.save()
    }

    // 주간 서술(로컬 FM) + Digest 저장
    @MainActor
    static func buildDigest(context: ModelContext, vault: VaultStore, consent: CloudConsent, now: Date) async -> Digest? {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now))!
        let cands = candidates(context: context, now: now)
        guard !cands.isEmpty else { return nil }

        var input = "이번 주 자주 돌아온 주제들:\n"
        for c in cands.prefix(8) {
            let ev = c.evolving == true ? "발전 중" : (c.evolving == false ? "비슷한 반복" : "")
            let en = c.avgEnergy.map { String(format: "에너지 %.0f%%", $0*100) } ?? ""
            input += "- \(c.theme.name): \(c.days)일 \(c.count)회 \(ev) \(en)\n"
        }
        let localFallback = "이번 주는 \(cands.prefix(3).map { $0.theme.name }.joined(separator: ", ")) 같은 주제가 자주 돌아왔어요."
        var cloud = false
        var narr: String?
        if consent.canSendToCloud, let key = consent.apiKey {
            let distilled = await Distillation.distill(from: start, to: now, context: context)   // 증류(봉인 제외, 원문 X)
            if let r = try? await CloudSynthesizer.synthesize(distilled: distilled, apiKey: key), !r.isEmpty {
                narr = r; cloud = true
                context.insert(Transmission(kind: "weekly", charCount: distilled.count))          // 전송 로그
            }
        }
        if narr == nil {   // 클라우드 OFF·실패 → 로컬 종합
            narr = await synth(
                "너는 한 주를 돌아보는 회고 도우미다. 아래 '자주 돌아온 주제'들을 보고 단순 나열 말고, 이번 주 마음이 어디로 향했는지·무엇이 발전하고 무엇이 맴돌았는지 통찰을 담아 한국어 5~7문장으로. 무엇을 지속하면 좋을지 부드럽게 짚어라.",
                input)
        }

        let df = DateFormatter(); df.dateFormat = "M월 d일"; df.locale = Locale(identifier: "ko_KR")
        var md = "## 주간 회고 (\(df.string(from: start)) ~ \(df.string(from: now)))\n\n"
        if cloud { md += "☁️ 깊은 종합(클라우드)\n\n" }
        md += "\(narr ?? localFallback)\n\n**자주 돌아온 주제**\n"
        for c in cands.prefix(8) {
            let badge = c.evolving == true ? "🌱진화" : (c.evolving == false ? "🔁맴돎" : "")
            md += "- \(c.theme.name) — \(c.days)일·\(c.count)회 \(badge)\n"
        }

        let d = Digest(kind: .weekly, periodStart: start, periodEnd: now, narrative: md, generatedInCloud: cloud)
        context.insert(d); try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(d)
        return d
    }

    private static func synth(_ instruction: String, _ input: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        do {
            let s = LanguageModelSession(instructions: instruction)
            let t = try await s.respond(to: input).content.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        } catch { return nil }
    }
}
