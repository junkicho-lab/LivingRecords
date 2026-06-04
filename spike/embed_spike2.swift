// 스파이크 ①-b — 한국어 contextual 임베딩 유사도 (NLContextualEmbedding)
// 실행: swift embed_spike2.swift
import Foundation
import NaturalLanguage

guard let model = NLContextualEmbedding(language: .korean) else {
    print("❌ 한국어 NLContextualEmbedding 생성 불가"); exit(1)
}
print("ℹ️ assets 있음? \(model.hasAvailableAssets)")

if !model.hasAvailableAssets {
    print("⬇️ assets 요청 중…")
    let sem = DispatchSemaphore(value: 0)
    var reqErr: Error? = nil
    model.requestAssets { _, error in reqErr = error; sem.signal() }
    sem.wait()
    if let e = reqErr { print("❌ assets 요청 실패: \(e)"); exit(1) }
}

do { try model.load() } catch { print("❌ load 실패: \(error)"); exit(1) }
print("✅ 모델 로드 (dim=\(model.dimension))\n")

func sentenceVector(_ text: String) -> [Double]? {
    guard let result = try? model.embeddingResult(for: text, language: .korean) else { return nil }
    var sum: [Double] = []
    var n = 0
    result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vec, _ in
        if sum.isEmpty { sum = [Double](repeating: 0, count: vec.count) }
        for i in 0..<vec.count { sum[i] += vec[i] }
        n += 1
        return true
    }
    guard n > 0 else { return nil }
    for i in 0..<sum.count { sum[i] /= Double(n) }
    return sum
}

func cosine(_ a: [Double], _ b: [Double]) -> Double {
    var dot = 0.0, na = 0.0, nb = 0.0
    for i in 0..<a.count { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
    return dot / (sqrt(na) * sqrt(nb) + 1e-9)
}

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
    guard let v = sentenceVector(s) else { print("⚠️ 벡터 실패: \(labels[i])"); exit(1) }
    vecs.append(v)
}

print("=== 코사인 유사도 행렬 ===")
print("      " + labels.map { $0.padding(toLength: 6, withPad: " ", startingAt: 0) }.joined())
for i in 0..<vecs.count {
    var row = labels[i].padding(toLength: 6, withPad: " ", startingAt: 0)
    for j in 0..<vecs.count { row += String(format: "%.2f  ", cosine(vecs[i], vecs[j])) }
    print(row)
}

func avg(_ xs: [Double]) -> Double { xs.reduce(0,+) / Double(xs.count) }
let withinA = [cosine(vecs[0],vecs[1]), cosine(vecs[0],vecs[2]), cosine(vecs[1],vecs[2])]
var crossAB: [Double] = []
for i in 0..<3 { for j in 3..<5 { crossAB.append(cosine(vecs[i], vecs[j])) } }

print("\n=== 판정 ===")
print(String(format: "A 내부 평균(같은 주제):   %.3f", avg(withinA)))
print(String(format: "A-B 교차(다른 주제):     %.3f", avg(crossAB)))
let gap = avg(withinA) - avg(crossAB)
print(String(format: "\n분리도(A내부 - A·B교차): %.3f  → %@", gap,
      gap > 0.10 ? "✅ 통합 가능성 양호" : "⚠️ 분리 약함(임베딩 교체 검토)"))
