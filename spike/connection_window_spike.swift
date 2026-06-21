// 스파이크 ⑨ — 연결(connections) 'now' 벡터: 전체 누적 vs 창(window) 한정
// 실행: swift spike/connection_window_spike.swift
// 가설: WeeklyReview.connections의 now=주제 전체 포착 평균이라 "이번 주 새로 가까워진"(isNew)
//       판정과 어긋난다. 최근에만 수렴한 연결이 옛 포착에 희석돼 link 임계조차 못 넘을 수 있다.
//       now를 '창 한정'으로 바꾸면 그 연결을 잡는지 실측한다.
import Foundation
import NaturalLanguage

let model = NLContextualEmbedding(language: .korean)!
if !model.hasAvailableAssets { print("⚠️ assets 없음 — 다운로드 시도"); model.requestAssets { _,_ in } }
try? model.load()

func embed(_ text: String) -> [Double]? {
    guard let r = try? model.embeddingResult(for: text, language: .korean) else { return nil }
    var sum: [Double] = []; var n = 0
    r.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { v, _ in
        if sum.isEmpty { sum = [Double](repeating: 0, count: v.count) }
        for i in 0..<v.count { sum[i] += v[i] }; n += 1; return true
    }
    guard n > 0 else { return nil }
    for i in 0..<sum.count { sum[i] /= Double(n) }
    return sum
}
func mean(_ vs: [[Double]]) -> [Double]? {
    guard let f = vs.first else { return nil }
    var s = [Double](repeating: 0, count: f.count)
    for v in vs where v.count == f.count { for i in 0..<v.count { s[i] += v[i] } }
    for i in 0..<s.count { s[i] /= Double(vs.count) }; return s
}
// 앱과 동일한 고정 참조 중심화
let refs = ["날씨가 흐려서 우산을 챙겼다","회의가 길어져 피곤하다","새 책을 한 권 샀다",
            "커피를 마시며 음악을 들었다","오랜만에 친구에게 연락했다","영화를 보고 감동했다",
            "예산을 다시 계산했다","버스를 놓쳐서 뛰었다","정원에 물을 주었다",
            "사진을 정리했다","산책을 하며 생각을 정리했다","저녁 메뉴를 고민했다"]
let center = mean(refs.compactMap { embed($0) })
func cosC(_ a: [Double], _ b: [Double]) -> Double {
    func cn(_ v: [Double]) -> [Double] {
        let c = (center?.count == v.count) ? zip(v, center!).map(-) : v
        let m = c.reduce(0){ $0 + $1*$1 }.squareRoot() + 1e-9
        return c.map { $0/m }
    }
    let x = cn(a), y = cn(b); return zip(x,y).reduce(0){ $0 + $1.0*$1.1 }
}

// 주제 = (이전 창 포착[], 최근 창 포착[])
struct Theme { let name: String; let prior: [String]; let recent: [String] }
let themes = [
    // A·B: 이전엔 서로 먼 주제였는데 최근에 둘 다 '건강·운동'으로 수렴 → 진짜 새 연결
    Theme(name: "직장",   prior: ["회의가 너무 많아 지친다","상사와 갈등이 있었다"],
                          recent: ["건강을 위해 운동을 시작했다","매일 아침 달리기를 한다"]),
    Theme(name: "식습관", prior: ["야식을 줄여야겠다","외식이 잦아 고민이다"],
                          recent: ["헬스장에 등록해 운동한다","꾸준히 달리기로 체력을 키운다"]),
    // C: 이전부터 줄곧 가까운 두 주제(글쓰기) → 새 연결 아님(둘 다)
    Theme(name: "일기",   prior: ["매일 일기를 쓴다","오늘 하루를 글로 남겼다"],
                          recent: ["일기 쓰는 습관을 이어간다","감정을 글로 적었다"]),
    Theme(name: "블로그", prior: ["블로그에 글을 올렸다","글쓰기를 꾸준히 한다"],
                          recent: ["블로그 글을 다시 썼다","에세이를 한 편 적었다"]),
]
let T = 0.15   // WeeklyReview.linkThreshold

struct Vecs { let name: String; let nowAll: [Double]; let nowWin: [Double]; let prior: [Double]? }
let V: [Vecs] = themes.map { t in
    let pe = t.prior.compactMap { embed($0) }, re = t.recent.compactMap { embed($0) }
    return Vecs(name: t.name, nowAll: mean(pe+re)!, nowWin: mean(re)!, prior: mean(pe))
}

func pad(_ s: String, _ w: Int) -> String { s.count >= w ? s : s + String(repeating: " ", count: w - s.count) }
func f3(_ d: Double) -> String { let s = String(format: "%.3f", d); return pad(s, 8) }
print("연결 판정 비교 (임계값 link=\(T))  [now=전체누적]  vs  [now=창한정]\n")
print(pad("쌍",14) + pad("prior",8) + pad("now全",8) + pad("now窓",8) + "| " + pad("현재(now全)",16) + "제안(now窓)")
for i in 0..<V.count { for j in (i+1)..<V.count {
    let a = V[i], b = V[j]
    let ps = (a.prior != nil && b.prior != nil) ? cosC(a.prior!, b.prior!) : -1
    let nAll = cosC(a.nowAll, b.nowAll)
    let nWin = cosC(a.nowWin, b.nowWin)
    // 현재 로직: link = now全 > T ; isNew = prior < T
    let linkAll = nAll > T, newAll = linkAll && ps < T
    let linkWin = nWin > T, newWin = linkWin && ps < T
    func tag(_ link: Bool, _ new: Bool) -> String { link ? (new ? "🔗 새 연결" : "🔗 연결") : "— 없음" }
    print(pad("\(a.name)~\(b.name)",14) + f3(ps) + f3(nAll) + f3(nWin) + "| " + pad(tag(linkAll,newAll),16) + tag(linkWin,newWin))
}}
print("\n해석: '직장~식습관'은 최근에만 건강·운동으로 수렴한 *진짜 새 연결*.")
print("      now全(전체누적)이 옛 포착에 희석돼 link를 놓치면 → 현재 로직 결함 확인.")
print("      now窓(창한정)이 그 연결을 잡으면 → 창 한정 now가 의도에 맞음.")
