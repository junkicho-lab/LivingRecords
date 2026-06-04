import Foundation
import SwiftData
import FoundationModels

// S6b 1단계 — 증류: 원문은 로컬에 두고, 주제별 '요약'으로 추상화한 층만 만든다. 봉인 제외.
enum Distillation {
    @MainActor
    static func distill(from start: Date, to end: Date, context: ModelContext) async -> String {
        let cal = Calendar.current
        let all = (try? context.fetch(FetchDescriptor<Capture>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        // 봉인 제외 + 기간 필터 (원문은 여기서만 쓰고, 밖으로는 요약만 나간다)
        let caps = all.filter { !$0.sealed && $0.createdAt >= start && $0.createdAt < end }
        guard !caps.isEmpty else { return "" }

        var byTheme: [String: [Capture]] = [:]; var order: [String] = []
        for c in caps {
            let n = c.theme?.name ?? "미분류"
            if byTheme[n] == nil { byTheme[n] = []; order.append(n) }
            byTheme[n]!.append(c)
        }

        var payload = "이번 주(봉인 제외) 주제별 요약:\n"
        for name in order {
            let cs = byTheme[name]!
            let days = Set(cs.map { cal.startOfDay(for: $0.createdAt) }).count
            let es = cs.compactMap { $0.energy }
            let energy = es.isEmpty ? "" : String(format: ", 에너지 %.0f%%", es.reduce(0,+)/Double(es.count)*100)
            // 로컬 FM이 원문을 요약(추상화). 실패 시 개수만.
            let summary = await summarize(cs.map { $0.text })
            payload += "- \(name) (\(days)일·\(cs.count)회\(energy)): \(summary)\n"
        }
        return payload
    }

    private static func summarize(_ texts: [String]) async -> String {
        let r = await LocalSynth.generate(   // FM→MLX 폴백, 둘 다 막히면 개수만
            "다음 같은 주제의 메모들을 1~2문장으로 요약하라. 구체적 흐름·변화 중심. 원문 인용 말고 추상적으로.",
            texts.joined(separator: "\n"))
        return r ?? "\(texts.count)개의 생각"
    }
}
