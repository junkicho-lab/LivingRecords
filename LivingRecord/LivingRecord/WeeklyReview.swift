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

// S9 — 냉각: 한때 뜨거웠다 조용해진 줄기. 지속 후보(최근 활발)와 분리해 '놓아줄까?'를 묻는다.
struct Cooling: Identifiable {
    let theme: Theme
    let priorCount: Int        // 직전 기간(창 앞 2주) 포착 수 — 한때의 뜨거움
    let recentCount: Int       // 최근 창 포착 수 — 식음 정도
    let daysSinceLast: Int     // 마지막 포착 이후 경과일
    var id: PersistentIdentifier { theme.persistentModelID }
}

// S10 — 연결: 주제 중심끼리 가까운 쌍. 강도 티어 + '이번 주 새로 가까워진' 강조 + 한 줄기로 묶기.
struct Connection: Identifiable {
    let a: Theme
    let b: Theme
    let strength: Double       // cosCentered 유사도
    let isNew: Bool            // 이번 주 처음 가까워짐(이전 중심으론 멀었음/데이터 부족)
    var id: String { "\(a.persistentModelID.hashValue)~\(b.persistentModelID.hashValue)" }
    var strong: Bool { strength > 0.30 }
}

// S11 — 피드백 고리: 지난 결정이 그 뒤 어떻게 됐나. 회고를 '돌아봄'으로 시작해 루프를 닫는다.
struct FollowUp: Identifiable {
    enum Outcome { case sustaining, slipping, resurfacing, holding }  // 이어짐/미끄러짐/되올라옴/보류
    let themeName: String
    let verdict: Verdict
    let recentCount: Int       // 이번 창 포착 수
    let outcome: Outcome
    let id = UUID()
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

    // S9 — 식어가는 줄기: 직전 2주엔 활발(≥3회)했는데 최근 창엔 거의 끊긴(≤1회) 주제.
    // 접은 주제(drop)·막 되살린 주제(이번 창 sustain)는 제외해 다시 보채지 않음.
    @MainActor
    static func coolingThemes(context: ModelContext, now: Date) -> [Cooling] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: today),
              let priorStart = cal.date(byAdding: .day, value: -windowDays * 3, to: today) else { return [] }
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        let decisions = (try? context.fetch(FetchDescriptor<Decision>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        var latestDec: [PersistentIdentifier: Decision] = [:]
        for d in decisions { if let t = d.theme { latestDec[t.persistentModelID] = d } }

        var out: [Cooling] = []
        for t in themes {
            if let dec = latestDec[t.persistentModelID] {
                if dec.verdict == .drop { continue }                              // 접은 줄기 제외
                if dec.verdict == .sustain && dec.createdAt >= windowStart { continue }  // 막 되살림 → 한 주기 쉼
            }
            let prior = t.captures.filter { $0.createdAt >= priorStart && $0.createdAt < windowStart }
            let recent = t.captures.filter { $0.createdAt >= windowStart }
            guard prior.count >= 3, recent.count <= 1 else { continue }           // 한때 뜨겁고 + 지금 거의 끊김
            let last = t.captures.map { $0.createdAt }.max() ?? priorStart
            let daysSince = cal.dateComponents([.day], from: last, to: now).day ?? 0
            guard daysSince >= 4 else { continue }                                 // 며칠 이상 조용
            out.append(Cooling(theme: t, priorCount: prior.count, recentCount: recent.count, daysSinceLast: daysSince))
        }
        return out.sorted { ($0.priorCount, $0.daysSinceLast) > ($1.priorCount, $1.daysSinceLast) }
    }

    // 되살리기: 다시 이어가기로. sustain 결정 기록 + 활성 복귀(한 주기 동안 냉각 목록에서 빠짐).
    @MainActor
    static func revive(_ theme: Theme, context: ModelContext) {
        context.insert(Decision(theme: theme, verdict: .sustain))
        theme.state = .active
        try? context.save()
    }

    static let fadeDays = 10   // 약속 생성 후 주제 활동 0이 이만큼 지나면 '잠잠해짐'

    // S8 — 이번 창의 약속(의도)들 + 생존 판정. surviving=약속 후 같은 주제에 새 포착 있음, faded=10일+활동 0.
    @MainActor
    static func commitments(context: ModelContext, now: Date) -> [Commitment] {
        let cal = Calendar.current
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now)) else { return [] }
        let all = (try? context.fetch(FetchDescriptor<Commitment>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        let inWindow = all.filter { $0.createdAt >= windowStart }
        let caps = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        for c in inWindow {
            c.status = survival(c, caps: caps, now: now)
            if c.status == .surviving { c.themeName = themeName(for: c.themeID, caps: caps) ?? c.themeName }  // 이름 변경 반영
        }
        try? context.save()
        return inWindow
    }

    private static func survival(_ c: Commitment, caps: [Capture], now: Date) -> CommitmentStatus {
        guard let tid = c.themeID else { return .open }
        if caps.contains(where: { $0.theme?.id == tid && $0.createdAt > c.createdAt }) { return .surviving }
        let days = Calendar.current.dateComponents([.day], from: c.createdAt, to: now).day ?? 0
        return days >= fadeDays ? .faded : .open
    }

    private static func themeName(for id: UUID?, caps: [Capture]) -> String? {
        guard let id else { return nil }
        return caps.first { $0.theme?.id == id }?.theme?.name
    }

    // S11 — 지난 결정의 현재. 한 주기(창) 이전에 내린 '최신' 결정만 보고(지켜볼 시간 필요), 이번 창 활동으로 결과 판정.
    @MainActor
    static func followUps(context: ModelContext, now: Date) -> [FollowUp] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: today),
              let lookback = cal.date(byAdding: .day, value: -windowDays * 3, to: today) else { return [] }
        let decisions = (try? context.fetch(FetchDescriptor<Decision>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        var latest: [PersistentIdentifier: Decision] = [:]
        for d in decisions { if let t = d.theme { latest[t.persistentModelID] = d } }   // 오름차순 → 최신이 남음

        var out: [FollowUp] = []
        for (_, d) in latest {
            guard let t = d.theme, d.createdAt >= lookback, d.createdAt < windowStart else { continue }
            let recent = t.captures.filter { $0.createdAt >= windowStart }.count
            let outcome: FollowUp.Outcome
            switch d.verdict {
            case .sustain: outcome = recent > 0 ? .sustaining : .slipping
            case .drop:    if recent == 0 { continue }; outcome = .resurfacing   // 조용히 정리된 건 노출 안 함
            case .hold:    outcome = .holding
            }
            out.append(FollowUp(themeName: t.name, verdict: d.verdict, recentCount: recent, outcome: outcome))
        }
        func rank(_ o: FollowUp.Outcome) -> Int {
            switch o { case .resurfacing: 3; case .slipping: 2; case .sustaining: 1; case .holding: 0 }
        }
        return out.sorted { rank($0.outcome) > rank($1.outcome) }
    }

    static let linkThreshold = 0.15

    // 연결(고도화): 주제 중심 유사도 + 강도 + 이번 주 새 연결 여부. best-effort.
    @MainActor
    static func connections(_ cands: [Candidate], now: Date) -> [Connection] {
        let cal = Calendar.current
        let windowStart = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now)) ?? now
        let center = EmbedderImpl.shared.centeringVector()
        struct Node { let theme: Theme; let now: [Double]; let prior: [Double]? }
        let nodes: [Node] = cands.compactMap { c in
            guard let nowVec = meanVec(c.theme.captures.compactMap { $0.embedding }) else { return nil }
            let priorVec = meanVec(c.theme.captures.filter { $0.createdAt < windowStart }.compactMap { $0.embedding })
            return Node(theme: c.theme, now: nowVec, prior: priorVec)
        }
        var out: [Connection] = []
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let s = cosCentered(nodes[i].now, nodes[j].now, center)
                guard s > linkThreshold else { continue }
                // 이전 중심끼리도 가까웠나? 둘 다 이전 데이터 있어야 비교 가능.
                let priorSim: Double? = (nodes[i].prior != nil && nodes[j].prior != nil)
                    ? cosCentered(nodes[i].prior!, nodes[j].prior!, center) : nil
                let isNew = (priorSim ?? -1) < linkThreshold   // 이전엔 멀었거나 데이터 없음 → 새 연결
                out.append(Connection(a: nodes[i].theme, b: nodes[j].theme, strength: s, isNew: isNew))
            }
        }
        // 새 연결 먼저, 그다음 강도
        let sorted = out.sorted { ($0.isNew ? 1 : 0, $0.strength) > ($1.isNew ? 1 : 0, $1.strength) }
        return Array(sorted.prefix(6))
    }

    // 한 줄기로 묶기: 작은 쪽을 큰 쪽으로 합쳐 큰 주제 이름을 보존.
    @MainActor
    static func mergeConnection(_ c: Connection, context: ModelContext, vault: VaultStore) {
        let (big, small) = c.a.captures.count >= c.b.captures.count ? (c.a, c.b) : (c.b, c.a)
        Curation.move(Array(small.captures), to: big, context: context, vault: vault)
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

        // S11 — 지난 결정의 현재(돌아봄)를 서술 입력 맨 앞에
        let follow = followUps(context: context, now: now)
        var input = ""
        if !follow.isEmpty {
            input += "지난 결정의 현재:\n"
            for f in follow.prefix(6) {
                let s: String
                switch f.outcome {
                case .sustaining:  s = "지속하기로 → 이번 주 \(f.recentCount)회 이어짐"
                case .slipping:    s = "지속하기로 → 이번 주 조용함"
                case .resurfacing: s = "접기로 했는데 → 이번 주 \(f.recentCount)회 다시 올라옴"
                case .holding:     s = "보류 중 → 이번 주 \(f.recentCount)회"
                }
                input += "- \(f.themeName): \(s)\n"
            }
        }
        input += "이번 주 자주 돌아온 주제들:\n"
        for c in cands.prefix(8) {
            let ev = c.evolving == true ? "발전 중" : (c.evolving == false ? "비슷한 반복" : "")
            let tr = c.trend == .rising ? "요즘 부쩍 늘어남" : (c.trend == .cooling ? "점점 잦아들고 식어감" : "꾸준")
            let en = c.avgEnergy.map { String(format: "에너지 %.0f%%", $0*100) } ?? ""
            let et = c.energyTrend.map { $0 > 0.05 ? "열기 오르는 중" : ($0 < -0.05 ? "열기 식는 중" : "") } ?? ""
            input += "- \(c.theme.name): \(c.days)일 \(c.count)회, \(tr), \(ev) \(en) \(et)\n"
        }
        // S10 — 새로 가까워진 연결을 서술 입력에 보탬(영감)
        let conns = connections(cands, now: now)
        let newConns = conns.filter { $0.isNew }
        if !newConns.isEmpty {
            input += "이번 주 새로 가까워진 주제: " + newConns.prefix(3).map { "\($0.a.name)↔\($0.b.name)" }.joined(separator: ", ") + "\n"
        }
        // S9 — 식어가는 줄기를 서술 입력에 보탬
        let cooling = coolingThemes(context: context, now: now)
        if !cooling.isEmpty {
            input += "한때 뜨거웠다 식어가는 주제: " + cooling.prefix(5).map {
                "\($0.theme.name)(한때 \($0.priorCount)회, \($0.daysSinceLast)일째 조용)"
            }.joined(separator: ", ") + "\n"
        }
        // S8 — 이번 주 다짐(의도)을 서술 입력에 보탬
        let coms = commitments(context: context, now: now)
        if !coms.isEmpty {
            input += "이번 주 다짐과 그 이후:\n"
            for c in coms.prefix(8) {
                let st = c.status == .surviving ? "이어지는 중" : (c.status == .faded ? "잠잠해짐" : "막 시작")
                input += "- \(c.text) (\(st))\n"
            }
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
                "너는 한 주를 돌아보는 회고 도우미다. '지난 결정의 현재'가 있으면 먼저 그것부터 짚어라(지속하기로 한 게 이어졌는지, 접은 게 다시 올라왔는지). 그다음 '자주 돌아온 주제'를 단순 나열 말고, 이번 주 마음이 어디로 향했는지·무엇이 떠오르고 무엇이 식어가는지·무엇이 발전하고 무엇이 맴돌았는지 통찰을 담아 한국어 6~8문장으로. 떠오르는 건 지속을, 식어가는 건 놓아줄지 부드럽게 짚어라.",
                input)
        }

        let df = DateFormatter(); df.dateFormat = "M월 d일"; df.locale = Locale(identifier: "ko_KR")
        var md = "## 주간 회고 (\(df.string(from: start)) ~ \(df.string(from: now)))\n\n"
        if cloud { md += "☁️ 깊은 종합(클라우드)\n\n" }
        md += "\(narr ?? localFallback)\n\n"
        if !follow.isEmpty {
            md += "**지난 회고 이후**\n"
            for f in follow.prefix(6) {
                let mark: String
                switch f.outcome {
                case .sustaining:  mark = "이어짐 ✓ (\(f.recentCount)회)"
                case .slipping:    mark = "조용해짐"
                case .resurfacing: mark = "다시 올라옴 ↑ (\(f.recentCount)회)"
                case .holding:     mark = "보류 중"
                }
                md += "- \(f.themeName) — \(PeriodReview.verdictLabel(f.verdict))했는데 → \(mark)\n"
            }
            md += "\n"
        }
        md += "**자주 돌아온 주제**\n"
        for c in cands.prefix(8) {
            let ev = c.evolving == true ? " 🌱진화" : (c.evolving == false ? " 🔁맴돎" : "")
            let tr = c.trend == .rising ? " ↑떠오름" : (c.trend == .cooling ? " ↓식어감" : "")
            md += "- \(c.theme.name) — \(c.days)일·\(c.count)회\(tr)\(ev)\n"
        }
        if !cooling.isEmpty {
            md += "\n**❄️ 식어가는 줄기**\n"
            for c in cooling.prefix(6) {
                md += "- \(c.theme.name) — 한때 \(c.priorCount)회, \(c.daysSinceLast)일째 조용\n"
            }
        }
        if !conns.isEmpty {
            md += "\n**연결**\n"
            for c in conns.prefix(5) {
                md += "- \(c.a.name) ↔ \(c.b.name)\(c.isNew ? " (새 연결)" : "")\n"
            }
        }
        if !coms.isEmpty {
            md += "\n**이번 주 다짐**\n"
            for c in coms.prefix(8) {
                let mark = c.status == .surviving ? "이어지는 중 ✓" : (c.status == .faded ? "잠잠해짐" : "막 시작")
                md += "- \(c.text) — \(mark)\n"
            }
        }

        let d = Digest(kind: .weekly, periodStart: start, periodEnd: now, narrative: md, generatedInCloud: cloud)
        context.insert(d); try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(d)
        return d
    }

    private static func synth(_ instruction: String, _ input: String) async -> String? {
        await LocalSynth.generate(instruction, input)   // FM→MLX 폴백
    }
}
