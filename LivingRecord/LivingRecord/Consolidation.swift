import Foundation
import SwiftData

// S4 — 임베딩 통합: 새 포착을 가장 가까운 주제에 붙이거나 새 주제 생성.
// 중심화(anisotropy 보정) + 코사인 임계값. (spike/cluster_spike.swift 검증, 임계값 ~0.0)
enum Consolidator {
    static let threshold = 0.1   // 고정 참조 중심화 기준(spike/fix_centroid_spike: 같은주제 0.215 vs 다른 0.05)

    @MainActor
    static func consolidate(_ capture: Capture, context: ModelContext, embedder: Embedder) {
        guard let vec = embedder.embed(capture.text) else { return }
        capture.embedding = vec

        // 중심 벡터 = 고정 참조 세트(사용자 데이터 X). 소수 포착에서도 안정적.
        guard let centroid = embedder.centeringVector(), centroid.count == vec.count else {
            try? context.save(); return
        }
        let dim = vec.count

        func centeredNorm(_ v: [Double]) -> [Double] {
            let c = zip(v, centroid).map { $0 - $1 }
            let m = (c.reduce(0) { $0 + $1 * $1 }).squareRoot() + 1e-9
            return c.map { $0 / m }
        }
        func cosine(_ a: [Double], _ b: [Double]) -> Double { zip(a, b).reduce(0) { $0 + $1.0 * $1.1 } }

        let target = centeredNorm(vec)
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        var best: Theme?; var bestSim = -2.0
        for t in themes {
            let te = t.captures.compactMap { $0.embedding }.filter { $0.count == dim }
            guard !te.isEmpty else { continue }
            var tc = [Double](repeating: 0, count: dim)
            for e in te { for i in 0..<dim { tc[i] += e[i] } }
            for i in 0..<dim { tc[i] /= Double(te.count) }
            let sim = cosine(target, centeredNorm(tc))
            if sim > bestSim { bestSim = sim; best = t }
        }

        if let best, bestSim > threshold {
            capture.theme = best
        } else {
            let t = Theme(name: placeholderName(capture.text))   // S4b에서 FM 이름짓기로 교체
            context.insert(t)
            capture.theme = t
        }
        try? context.save()
    }

    static func placeholderName(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
    }
}
