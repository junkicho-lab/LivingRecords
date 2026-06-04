// 스파이크 ①-c — 한국어 contextual 임베딩 + 중심화(anisotropy 보정)
// 실행: swift embed_spike3.swift
import Foundation
import NaturalLanguage

guard let model = NLContextualEmbedding(language: .korean) else { print("❌ 생성 불가"); exit(1) }
if !model.hasAvailableAssets {
    let sem = DispatchSemaphore(value: 0); model.requestAssets { _,_ in sem.signal() }; sem.wait()
}
try! model.load()

func vec(_ text: String) -> [Double] {
    let r = try! model.embeddingResult(for: text, language: .korean)
    var sum: [Double] = []; var n = 0
    r.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { v, _ in
        if sum.isEmpty { sum = [Double](repeating: 0, count: v.count) }
        for i in 0..<v.count { sum[i] += v[i] }; n += 1; return true
    }
    for i in 0..<sum.count { sum[i] /= Double(n) }; return sum
}
func norm(_ a: [Double]) -> [Double] { let m = sqrt(a.reduce(0){$0+$1*$1})+1e-9; return a.map{$0/m} }
func cos(_ a: [Double], _ b: [Double]) -> Double { zip(a,b).reduce(0){$0+$1.0*$1.1} } // 정규화 후엔 내적=코사인
func avg(_ xs: [Double]) -> Double { xs.reduce(0,+)/Double(xs.count) }

// 그룹: A=수업회고, B=음식, C=운동/야외
let groups: [String:[String]] = [
  "A": ["오늘 수업을 돌아보며 무엇이 좋았는지 적었다","수업이 끝나고 회고를 남겼다",
        "내 수업 방식에 대해 다시 생각해 봤다","이번 수업에서 아쉬웠던 점을 메모했다"],
  "B": ["점심으로 김치찌개를 맛있게 먹었다","저녁에 파스타를 해 먹었다","아침은 토스트로 간단히 때웠다"],
  "C": ["주말에 친구들과 등산을 다녀왔다","아침에 공원을 달렸다","자전거를 타고 강변을 돌았다"],
]
var items: [(g:String, t:String, raw:[Double])] = []
for (g, ss) in groups.sorted(by: {$0.key<$1.key}) { for s in ss { items.append((g, s, vec(s))) } }

// 중심화: 전체 평균 벡터를 빼고 재정규화
let dim = items[0].raw.count
var centroid = [Double](repeating: 0, count: dim)
for it in items { for i in 0..<dim { centroid[i] += it.raw[i] } }
for i in 0..<dim { centroid[i] /= Double(items.count) }

func sep(centered: Bool) -> (within: Double, cross: Double) {
    let vs = items.map { it -> [Double] in
        if centered { return norm(zip(it.raw, centroid).map{$0-$1}) }
        return norm(it.raw)
    }
    var within: [Double] = [], cross: [Double] = []
    for i in 0..<items.count { for j in (i+1)..<items.count {
        let c = cos(vs[i], vs[j])
        if items[i].g == items[j].g { within.append(c) } else { cross.append(c) }
    }}
    return (avg(within), avg(cross))
}

let raw = sep(centered: false)
let cen = sep(centered: true)
print("=== 같은그룹 vs 다른그룹 평균 코사인 ===")
print(String(format: "원본    : 같은 %.3f / 다른 %.3f → 분리도 %.3f", raw.within, raw.cross, raw.within-raw.cross))
print(String(format: "중심화  : 같은 %.3f / 다른 %.3f → 분리도 %.3f", cen.within, cen.cross, cen.within-cen.cross))
let g = cen.within - cen.cross
print(String(format: "\n중심화 분리도 %.3f → %@", g,
  g > 0.15 ? "✅ 통합 충분" : (g > 0.08 ? "🟡 통합 가능(임계값 튜닝 필요)" : "⚠️ 부족(임베딩 교체 검토)")))
