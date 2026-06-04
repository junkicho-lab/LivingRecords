// 스파이크 (v4 검색) — 질문→포착 의미 검색 품질. 중심화 코사인 랭킹이 한국어로 쓸 만한가?
// 기대: 각 질문에 의미상 맞는 포착이 top에. 거칠면(엉뚱한 게 1위) 하이브리드에서 의미는 '보조'로.
import Foundation
import NaturalLanguage

let model = NLContextualEmbedding(language: .korean)
if let m = model, !m.hasAvailableAssets { m.requestAssets { _, _ in }; Thread.sleep(forTimeInterval: 2) }
try? model?.load()

func embed(_ text: String) -> [Double]? {
    guard let model, let r = try? model.embeddingResult(for: text, language: .korean) else { return nil }
    var sum: [Double] = []; var n = 0
    r.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { v, _ in
        if sum.isEmpty { sum = [Double](repeating: 0, count: v.count) }
        for i in 0..<v.count { sum[i] += v[i] }; n += 1; return true
    }
    guard n > 0 else { return nil }
    for i in 0..<sum.count { sum[i] /= Double(n) }
    return sum
}

let refs = ["날씨가 흐려서 우산을 챙겼다","회의가 길어져 피곤하다","새 책을 한 권 샀다","커피를 마시며 음악을 들었다",
            "오랜만에 친구에게 연락했다","영화를 보고 감동했다","예산을 다시 계산했다","버스를 놓쳐서 뛰었다",
            "정원에 물을 주었다","사진을 정리했다","산책을 하며 생각을 정리했다","저녁 메뉴를 고민했다"]
var center = [Double](repeating: 0, count: 512); var cn = 0
for s in refs { if let v = embed(s) { for i in 0..<v.count { center[i] += v[i] }; cn += 1 } }
for i in 0..<center.count { center[i] /= Double(max(cn,1)) }

func cosC(_ a: [Double], _ b: [Double]) -> Double {
    func cen(_ v: [Double]) -> [Double] {
        let c = zip(v, center).map(-); let m = c.reduce(0){$0+$1*$1}.squareRoot()+1e-9; return c.map{$0/m}
    }
    let x = cen(a), y = cen(b); return zip(x,y).reduce(0){$0+$1.0*$1.1}
}

// 코퍼스(주제 태그는 채점용)
let corpus: [(String, String)] = [
    ("수업","오늘 수업에서 발표 방식을 바꿨더니 아이들 눈빛이 살았다"),
    ("수업","학부모 상담 준비를 어떻게 할지 고민이다"),
    ("운동","아침마다 달리기를 했더니 몸이 가벼워졌다"),
    ("운동","헬스장에서 처음으로 스쿼트를 제대로 배웠다"),
    ("음식","저녁으로 김치찌개를 끓여 먹었다"),
    ("음식","새로 생긴 파스타집이 꽤 괜찮았다"),
    ("글쓰기","매일 30분씩 글 쓰는 습관을 들이고 싶다"),
    ("글쓰기","블로그에 회고 글을 한 편 올렸다"),
    ("관계","오랜 친구와 통화하며 마음이 풀렸다"),
    ("관계","팀원과의 갈등을 어떻게 풀지 막막하다"),
    ("돈","이번 달 지출을 정리하니 외식비가 컸다"),
    ("자연","주말에 산에 올라 단풍을 봤다"),
]
let embedded = corpus.compactMap { (tag, t) in embed(t).map { (tag, t, $0) } }

let queries: [(String, String)] = [   // (질문, 기대 태그)
    ("건강을 위해 운동하기", "운동"),
    ("가르치는 일", "수업"),
    ("끼니 챙기기", "음식"),
    ("꾸준히 글 쓰기", "글쓰기"),
    ("사람들과의 관계", "관계"),
    ("돈 관리", "돈"),
]

var top1 = 0, top3 = 0
for (q, expect) in queries {
    guard let qv = embed(q) else { continue }
    let ranked = embedded.map { ($0.0, $0.1, cosC(qv, $0.2)) }.sorted { $0.2 > $1.2 }
    let names = ranked.prefix(3).map { "\($0.0)(\(String(format:"%.2f",$0.2)))" }.joined(separator: ", ")
    if ranked.first?.0 == expect { top1 += 1 }
    if ranked.prefix(3).contains(where: { $0.0 == expect }) { top3 += 1 }
    let mark = ranked.first?.0 == expect ? "✅" : "❓"
    print("\(mark) '\(q)' → \(names)  [기대 \(expect)]")
}
print("\ntop-1 정확 \(top1)/\(queries.count), top-3 포함 \(top3)/\(queries.count)")
