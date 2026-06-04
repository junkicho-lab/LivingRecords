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
    let evolutionScore: Double?  // 전·후반 의미 드리프트(클수록 진화). 표시 nuance용.
    let momentum: Double     // -1~1: 음수=식어감(냉각), 0=꾸준, 양수=떠오름
    let energyTrend: Double?  // -1~1: 에너지 전→후반 변화(양수=오름)
    let latestVerdict: Verdict?
    var id: PersistentIdentifier { theme.persistentModelID }

    enum Trend { case rising, steady, cooling }   // 떠오름/꾸준/식어감
    var trend: Trend {
        if momentum > 0.34 { return .rising }
        if momentum < -0.34 { return .cooling }
        return .steady
    }
    // 지속 가치 점수: 반복(일수·횟수) 중심 + 떠오르는 흐름·에너지·진화를 가산.
    var sustainScore: Double {
        Double(days) * 2 + Double(count) + (avgEnergy ?? 0) * 2
            + momentum * 1.5 + (evolutionScore ?? 0)
    }
}

enum WeeklyReview {
    static let windowDays = 7

    // 지속 후보(결정적): 기간 내 2회 이상 등장한 주제. 반복도·에너지·진화·모멘텀.
    @MainActor
    static func candidates(context: ModelContext, now: Date) -> [Candidate] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: today) else { return [] }
        let recentDays = max(1, windowDays / 2)               // 창의 '최근 절반'
        let earlierDays = max(1, windowDays - recentDays)
        let recentStart = cal.date(byAdding: .day, value: -recentDays, to: today) ?? windowStart
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
            // 모멘텀: 최근 절반 vs 이전 절반의 '하루당 활동률' 비교 → 떠오름/식어감.
            let recentN = caps.filter { $0.createdAt >= recentStart }.count
            let recentRate = Double(recentN) / Double(recentDays)
            let earlierRate = Double(caps.count - recentN) / Double(earlierDays)
            let momentum = (recentRate + earlierRate) > 0
                ? (recentRate - earlierRate) / (recentRate + earlierRate) : 0
            let (evScore, evolving) = evolutionSignal(caps)
            out.append(Candidate(theme: t, days: days, count: caps.count, avgEnergy: avgE,
                                 evolving: evolving, evolutionScore: evScore,
                                 momentum: momentum, energyTrend: energyTrend(caps),
                                 latestVerdict: verdict))
        }
        // 지속 가치 점수(반복 중심 + 떠오름·에너지·진화 가산)
        return out.sorted { $0.sustainScore > $1.sustainScore }
    }

    // 시간 인식형 진화/맴돎: 시간순 전반부 vs 후반부 중심이 옮겨갔으면 진화, 비슷하면 맴돎.
    // 반환: (드리프트 점수 0~, 진화여부 Bool?). 임베딩 3개부터 동작(전반:floor, 후반:나머지).
    private static func evolutionSignal(_ caps: [Capture]) -> (Double?, Bool?) {
        let embs = caps.sorted { $0.createdAt < $1.createdAt }.compactMap { $0.embedding }
        guard embs.count >= 3 else { return (nil, nil) }
        let mid = embs.count / 2
        guard let early = meanVec(Array(embs[0..<mid])), let late = meanVec(Array(embs[mid...])) else { return (nil, nil) }
        let center = EmbedderImpl.shared.centeringVector()
        let drift = 1 - cosCentered(early, late, center)
        return (drift, drift > 0.22)   // 전·후반이 충분히 다르면 진화, 비슷하면 맴돎
    }

    // 에너지 추세: 에너지 있는 포착을 시간순 전·후반으로 갈라 평균 차(후반-전반). 4개 미만이면 보류.
    private static func energyTrend(_ caps: [Capture]) -> Double? {
        let withE = caps.filter { $0.energy != nil }.sorted { $0.createdAt < $1.createdAt }
        guard withE.count >= 4 else { return nil }
        let mid = withE.count / 2
        let early = withE[0..<mid].compactMap { $0.energy }
        let late = withE[mid...].compactMap { $0.energy }
        guard !early.isEmpty, !late.isEmpty else { return nil }
        return late.reduce(0,+)/Double(late.count) - early.reduce(0,+)/Double(early.count)
    }

    // 연결: 주제 중심끼리 유사도가 높은 쌍(관련 있어 보임). best-effort.
    @MainActor
    static func relatedPairs(_ cands: [Candidate]) -> [(String, String)] {
        let center = EmbedderImpl.shared.centeringVector()
        let centroids: [(name: String, vec: [Double])] = cands.compactMap { c in
            meanVec(c.theme.captures.compactMap { $0.embedding }).map { (c.theme.name, $0) }
        }
        var scored: [(String, String, Double)] = []
        for i in 0..<centroids.count {
            for j in (i + 1)..<centroids.count {
                let s = cosCentered(centroids[i].vec, centroids[j].vec, center)
                if s > 0.15 { scored.append((centroids[i].name, centroids[j].name, s)) }
            }
        }
        return scored.sorted { $0.2 > $1.2 }.prefix(5).map { ($0.0, $0.1) }
    }

    private static func meanVec(_ vs: [[Double]]) -> [Double]? {
        guard let first = vs.first else { return nil }
        var s = [Double](repeating: 0, count: first.count)
        for v in vs where v.count == first.count { for i in 0..<v.count { s[i] += v[i] } }
        for i in 0..<s.count { s[i] /= Double(vs.count) }
        return s
    }

    private static func cosCentered(_ a: [Double], _ b: [Double], _ center: [Double]?) -> Double {
        func cn(_ v: [Double]) -> [Double] {
            let c = (center?.count == v.count) ? zip(v, center!).map(-) : v
            let m = c.reduce(0) { $0 + $1 * $1 }.squareRoot() + 1e-9
            return c.map { $0 / m }
        }
        let x = cn(a), y = cn(b)
        return zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
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
            let tr = c.trend == .rising ? "요즘 부쩍 늘어남" : (c.trend == .cooling ? "점점 잦아들고 식어감" : "꾸준")
            let en = c.avgEnergy.map { String(format: "에너지 %.0f%%", $0*100) } ?? ""
            let et = c.energyTrend.map { $0 > 0.05 ? "열기 오르는 중" : ($0 < -0.05 ? "열기 식는 중" : "") } ?? ""
            input += "- \(c.theme.name): \(c.days)일 \(c.count)회, \(tr), \(ev) \(en) \(et)\n"
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
                "너는 한 주를 돌아보는 회고 도우미다. 아래 '자주 돌아온 주제'들을 보고 단순 나열 말고, 이번 주 마음이 어디로 향했는지·무엇이 떠오르고(부쩍 늘어남) 무엇이 식어가는지·무엇이 발전하고 무엇이 맴돌았는지 통찰을 담아 한국어 5~7문장으로. 떠오르는 주제는 지속을, 식어가는 주제는 놓아줄지 부드럽게 짚어라.",
                input)
        }

        let df = DateFormatter(); df.dateFormat = "M월 d일"; df.locale = Locale(identifier: "ko_KR")
        var md = "## 주간 회고 (\(df.string(from: start)) ~ \(df.string(from: now)))\n\n"
        if cloud { md += "☁️ 깊은 종합(클라우드)\n\n" }
        md += "\(narr ?? localFallback)\n\n**자주 돌아온 주제**\n"
        for c in cands.prefix(8) {
            let ev = c.evolving == true ? " 🌱진화" : (c.evolving == false ? " 🔁맴돎" : "")
            let tr = c.trend == .rising ? " ↑떠오름" : (c.trend == .cooling ? " ↓식어감" : "")
            md += "- \(c.theme.name) — \(c.days)일·\(c.count)회\(tr)\(ev)\n"
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
