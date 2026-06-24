import Foundation
import SwiftData
import FoundationModels

// S5 — 일일 정리(로컬). 통찰 중심 서술 + 최근 흐름(반복) 연결. 나열 지양. 클라우드 미사용.
enum DailyDigest {
    @MainActor
    static func build(for day: Date, context: ModelContext, vault: VaultStore) async -> Digest? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start),
              let weekAgo = cal.date(byAdding: .day, value: -7, to: start) else { return nil }

        let all = (try? context.fetch(FetchDescriptor<Capture>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let today = all.filter { $0.createdAt >= start && $0.createdAt < end }
        guard !today.isEmpty else { return nil }

        // 오늘 주제별 묶기
        var byTheme: [String: [Capture]] = [:]; var order: [String] = []
        for c in today {
            let name = c.theme?.name ?? "미분류"
            if byTheme[name] == nil { byTheme[name] = []; order.append(name) }
            byTheme[name]!.append(c)
        }

        // 최근 흐름(반복): 오늘 주제가 직전 7일에 며칠 등장했나 (결정적)
        let recent = all.filter { $0.createdAt >= weekAgo && $0.createdAt < start }
        var flow: [(name: String, days: Int)] = []
        for name in order {
            let days = Set(recent.filter { $0.theme?.name == name }
                .map { cal.startOfDay(for: $0.createdAt) }).count
            if days > 0 { flow.append((name, days)) }
        }

        // 에너지 하이라이트
        func avgE(_ cs: [Capture]) -> Double? {
            let es = cs.compactMap { $0.energy }; return es.isEmpty ? nil : es.reduce(0,+)/Double(es.count)
        }
        let topEnergy = order.compactMap { n in avgE(byTheme[n]!).map { (n, $0) } }.max { $0.1 < $1.1 }?.0

        // FM 입력 구성
        var input = "오늘 적은 생각(주제별):\n"
        for name in order {
            input += "[\(name)] " + byTheme[name]!.map { $0.text }.joined(separator: " / ") + "\n"
        }
        if let t = topEnergy { input += "오늘 에너지가 높았던 주제: \(t)\n" }
        if !flow.isEmpty {
            input += "최근 흐름: " + flow.map { "'\($0.name)' 최근 \($0.days)일 등장" }.joined(separator: ", ") + "\n"
        }

        let df = DateFormatter(); df.dateFormat = "M월 d일"; df.locale = Locale(identifier: "ko_KR")
        var md = "## \(df.string(from: start)) 오늘의 정리\n\n"

        let style = Templates.activeDirective(context: context)   // 사용자 템플릿 스타일
        let insight = await synth(
            instruction: "너는 사려 깊은 회고 도우미다. 아래 오늘의 생각을 '단순 나열하지 말고' 흐름과 마음의 방향을 짚어 한국어로 써라. '최근 흐름'이 있으면 오늘과 연결해 무엇이 이어지고 무엇이 새로운지 언급하라. 스타일: \(style)",
            input: input)
        md += (insight ?? "오늘은 \(order.joined(separator: ", "))에 대한 생각을 남겼어요.") + "\n\n"

        // 이어지는 흐름(결정적, 반복 신호)
        let recurring = flow.filter { $0.days >= 1 }
        if !recurring.isEmpty {
            md += "🔁 이어지는 흐름: " + recurring.map { "\($0.name)(최근 \($0.days)일)" }.joined(separator: " · ") + "\n\n"
        }
        md += "오늘 다룬 것: " + order.joined(separator: " · ") + "\n"

        let q = await synth(
            instruction: "다음 생각들을 보고 내일 이어서 더 깊이 생각해볼 질문 하나만 한국어로. 질문만, 한 문장. 뻔하지 않게.",
            input: input) ?? "오늘 가장 마음이 머문 생각은 무엇이었나요?"
        md += "\n**내일 이어볼 질문**\n- \(q)\n"

        let d = Digest(kind: .daily, periodStart: start, periodEnd: end, narrative: md, generatedInCloud: false)
        d.sealedDerived = today.contains { $0.sealed }   // 봉인 원문이 서술 합성에 들어갔으면 봉인/로
        context.insert(d)
        try? context.save()
        try? ObsidianMirrorImpl(store: vault).mirror(d)
        return d
    }

    private static func synth(instruction: String, input: String) async -> String? {
        await LocalSynth.generate(instruction, input)   // FM→MLX 폴백
    }
}
