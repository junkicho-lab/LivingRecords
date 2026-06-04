// 스파이크 ① — 한국어 의미 임베딩 유사도 (주제 통합 검증)
// 실행: swift embed_spike.swift
import Foundation
import NaturalLanguage

func meanWordVector(_ text: String, _ emb: NLEmbedding) -> [Double]? {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text
    var vecs: [[Double]] = []
    let range = text.startIndex..<text.endIndex
    tokenizer.enumerateTokens(in: range) { r, _ in
        let word = String(text[r])
        if let v = emb.vector(for: word) { vecs.append(v) }
        return true
    }
    guard let first = vecs.first else { return nil }
    var mean = [Double](repeating: 0, count: first.count)
    for v in vecs { for i in 0..<v.count { mean[i] += v[i] } }
    for i in 0..<mean.count { mean[i] /= Double(vecs.count) }
    return mean
}

func cosine(_ a: [Double], _ b: [Double]) -> Double {
    var dot = 0.0, na = 0.0, nb = 0.0
    for i in 0..<a.count { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
    return dot / (sqrt(na) * sqrt(nb) + 1e-9)
}

guard let emb = NLEmbedding.wordEmbedding(for: .korean) else {
    print("❌ 한국어 word embedding 사용 불가"); exit(1)
}
print("✅ 한국어 word embedding 로드 (dim=\(emb.dimension))\n")

// A* = 같은 주제(수업 회고)를 다르게 표현 / B* = 무관한 주제
let labels = ["A1","A2","A3","B1","B2"]
let sentences = [
  "오늘 수업을 돌아보며 무엇이 좋았는지 적었다",
  "수업이 끝나고 회고를 남겼다",
  "내 수업 방식에 대해 다시 생각해 봤다",
  "주말에 친구들과 등산을 다녀왔다",
  "점심으로 김치찌개를 맛있게 먹었다",
]

var vecs: [[Double]] = []
for (i, s) in sentences.enumerated() {
    guard let v = meanWordVector(s, emb) else {
        print("⚠️ 벡터 실패: \(labels[i]) \(s)"); exit(1)
    }
    vecs.append(v)
}

print("=== 코사인 유사도 행렬 ===")
print("      " + labels.map { $0.padding(toLength: 6, withPad: " ", startingAt: 0) }.joined())
for i in 0..<vecs.count {
    var row = labels[i].padding(toLength: 6, withPad: " ", startingAt: 0)
    for j in 0..<vecs.count {
        row += String(format: "%.2f  ", cosine(vecs[i], vecs[j]))
    }
    print(row)
}

func avg(_ xs: [Double]) -> Double { xs.reduce(0,+) / Double(xs.count) }
let withinA = [cosine(vecs[0],vecs[1]), cosine(vecs[0],vecs[2]), cosine(vecs[1],vecs[2])]
let withinB = [cosine(vecs[3],vecs[4])]
var crossAB: [Double] = []
for i in 0..<3 { for j in 3..<5 { crossAB.append(cosine(vecs[i], vecs[j])) } }

print("\n=== 판정 ===")
print(String(format: "A 내부 평균(같은 주제):  %.3f", avg(withinA)))
print(String(format: "B 내부(무관 쌍):        %.3f", avg(withinB)))
print(String(format: "A-B 교차(서로 다른 주제): %.3f", avg(crossAB)))
let gap = avg(withinA) - avg(crossAB)
print(String(format: "\n분리도(A내부 - A·B교차): %.3f  → %@", gap,
      gap > 0.10 ? "✅ 통합 가능성 양호" : "⚠️ 분리 약함(임베딩 교체 검토)"))
