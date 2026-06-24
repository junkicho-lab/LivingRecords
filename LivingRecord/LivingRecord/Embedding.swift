import Foundation
import NaturalLanguage

// 벡터 보조 — 중심(평균)과 중심화 코사인. 주제 배정 후보 순위에 쓰임(WeeklyReview는 자체 사본 유지).
enum VectorMath {
    static func mean(_ vs: [[Double]]) -> [Double]? {
        guard let first = vs.first else { return nil }
        var s = [Double](repeating: 0, count: first.count); var n = 0
        for v in vs where v.count == first.count { for i in 0..<v.count { s[i] += v[i] }; n += 1 }
        guard n > 0 else { return nil }
        for i in 0..<s.count { s[i] /= Double(n) }   // 유효 벡터 수로 나눔
        return s
    }
    // 고정 중심을 빼고(anisotropy 보정) 코사인. 차원 불일치 시 -1.
    static func cosCentered(_ a: [Double], _ b: [Double], center: [Double]?) -> Double {
        guard a.count == b.count else { return -1 }
        func cn(_ v: [Double]) -> [Double] {
            let c = (center?.count == v.count) ? zip(v, center!).map(-) : v
            let m = c.reduce(0) { $0 + $1 * $1 }.squareRoot() + 1e-9
            return c.map { $0 / m }
        }
        let x = cn(a), y = cn(b)
        return zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

// S4 — 한국어 contextual 임베딩(평균 풀링). 중심화는 통합 시점에 적용(전역 centroid 동적).
final class EmbedderImpl: Embedder {
    static let shared = EmbedderImpl()
    private let model: NLContextualEmbedding?
    private var cachedCentering: [Double]?

    // 다양한 한국어 참조 문장 → 고정 중심 벡터(모델 anisotropy 보정).
    // 사용자 데이터로 중심화하면 소수일 때 깨지므로 고정 세트를 쓴다. (spike/fix_centroid_spike)
    private static let referenceSentences = [
        "날씨가 흐려서 우산을 챙겼다", "회의가 길어져 피곤하다", "새 책을 한 권 샀다",
        "커피를 마시며 음악을 들었다", "오랜만에 친구에게 연락했다", "영화를 보고 감동했다",
        "예산을 다시 계산했다", "버스를 놓쳐서 뛰었다", "정원에 물을 주었다",
        "사진을 정리했다", "산책을 하며 생각을 정리했다", "저녁 메뉴를 고민했다",
    ]

    func centeringVector() -> [Double]? {
        if let c = cachedCentering { return c }
        var sum: [Double] = []; var n = 0
        for s in Self.referenceSentences {
            guard let v = embed(s) else { continue }
            if sum.isEmpty { sum = [Double](repeating: 0, count: v.count) }
            for i in 0..<v.count { sum[i] += v[i] }; n += 1
        }
        guard n > 0 else { return nil }
        for i in 0..<sum.count { sum[i] /= Double(n) }
        cachedCentering = sum
        return sum
    }

    private init() {
        let m = NLContextualEmbedding(language: .korean)
        if let m, !m.hasAvailableAssets {
            m.requestAssets { _, _ in }   // best-effort 다운로드(없으면 임베딩 nil → 주제 미할당)
        }
        try? m?.load()
        model = m
    }

    func embed(_ text: String) -> [Double]? {
        guard let model,
              let r = try? model.embeddingResult(for: text, language: .korean) else { return nil }
        var sum: [Double] = []; var n = 0
        r.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { v, _ in
            if sum.isEmpty { sum = [Double](repeating: 0, count: v.count) }
            for i in 0..<v.count { sum[i] += v[i] }
            n += 1; return true
        }
        guard n > 0 else { return nil }
        for i in 0..<sum.count { sum[i] /= Double(n) }
        return sum
    }
}
