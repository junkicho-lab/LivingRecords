// 스파이크 — 임베딩 통합(온라인 그리디 군집화) 검증
// 중심화한 한국어 임베딩으로 임계값 기반 클러스터링 → 의도한 3그룹 형성?
import Foundation
import NaturalLanguage

guard let model = NLContextualEmbedding(language: .korean) else { print("❌"); exit(1) }
if !model.hasAvailableAssets { let s = DispatchSemaphore(value:0); model.requestAssets{_,_ in s.signal()}; s.wait() }
try! model.load()

func rawVec(_ t: String) -> [Double] {
    let r = try! model.embeddingResult(for: t, language: .korean)
    var sum: [Double] = []; var n = 0
    r.enumerateTokenVectors(in: t.startIndex..<t.endIndex) { v,_ in
        if sum.isEmpty { sum = [Double](repeating:0,count:v.count) }
        for i in 0..<v.count { sum[i]+=v[i] }; n+=1; return true
    }
    for i in 0..<sum.count { sum[i]/=Double(n) }; return sum
}
func norm(_ a:[Double])->[Double]{ let m=sqrt(a.reduce(0){$0+$1*$1})+1e-9; return a.map{$0/m} }
func cos(_ a:[Double],_ b:[Double])->Double{ zip(a,b).reduce(0){$0+$1.0*$1.1} }

let labeled: [(g:String,t:String)] = [
  ("수업","오늘 수업을 돌아보며 무엇이 좋았는지 적었다"),
  ("수업","수업이 끝나고 회고를 남겼다"),
  ("수업","이번 수업에서 아쉬웠던 점을 메모했다"),
  ("음식","점심으로 김치찌개를 맛있게 먹었다"),
  ("음식","저녁에 파스타를 해 먹었다"),
  ("운동","주말에 친구들과 등산을 다녀왔다"),
  ("운동","아침에 공원을 달렸다"),
]
let raws = labeled.map { rawVec($0.t) }
let dim = raws[0].count
var centroid = [Double](repeating:0,count:dim)
for v in raws { for i in 0..<dim { centroid[i]+=v[i] } }
for i in 0..<dim { centroid[i]/=Double(raws.count) }
let vecs = raws.map { norm(zip($0,centroid).map{$0-$1}) }   // 중심화 + 정규화

func cluster(_ threshold: Double) -> [[Int]] {
    var clusters: [[Int]] = []; var cents: [[Double]] = []
    for (i,v) in vecs.enumerated() {
        var best = -2.0; var bestC = -1
        for (c,ct) in cents.enumerated() { let s = cos(v, norm(ct)); if s>best { best=s; bestC=c } }
        if best > threshold {
            clusters[bestC].append(i); for k in 0..<dim { cents[bestC][k] += v[k] }
        } else { clusters.append([i]); cents.append(v) }
    }
    return clusters
}
print("임계값 쓸기 (기대: 3개 순수 클러스터):")
for t in [-0.15, -0.10, -0.05, 0.0, 0.05] {
    let cs = cluster(t)
    let pure = cs.allSatisfy { Set($0.map{labeled[$0].g}).count == 1 }
    let comp = cs.map { Set($0.map{labeled[$0].g}).sorted().joined(separator:"+") }
    print(String(format: "  t=%.2f → %d개 %@  %@", t, cs.count, pure ? "순수":"섞임", "\(comp)"))
}
print("\n해석: 보수적(순수) 군집화가 안전 — 과분할은 '합치기' 큐레이션으로 해결. 잘못된 병합이 더 위험.")
