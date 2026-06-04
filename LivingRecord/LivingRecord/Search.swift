import Foundation

// v4 검색 — 의미 검색(보조). 스파이크 ⑧: 임베딩 랭킹은 거칠어 정밀 신뢰 불가 → 전문 검색이 주력,
// 의미는 '비슷한 기록(추정)'으로 임계값+상위 소수만. 질문을 임베딩해 중심화 코사인 비교.
enum SemanticSearch {
    static func similar(to query: String, in captures: [Capture],
                        limit: Int = 6, threshold: Double = 0.30) -> [Capture] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2, let qv = EmbedderImpl.shared.embed(q) else { return [] }
        let center = EmbedderImpl.shared.centeringVector()
        let scored: [(Capture, Double)] = captures.compactMap { c in
            guard let e = c.embedding else { return nil }
            return (c, cosCentered(qv, e, center))
        }
        return scored.filter { $0.1 > threshold }.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
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
}
