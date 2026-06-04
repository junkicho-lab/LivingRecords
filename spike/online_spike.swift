// 스파이크 — 앱과 동일한 순차 온라인 통합(고정 참조 중심화 + 임계값 0.1) 재현
import Foundation
import NaturalLanguage

guard let model = NLContextualEmbedding(language: .korean) else { print("❌"); exit(1) }
if !model.hasAvailableAssets { let s=DispatchSemaphore(value:0); model.requestAssets{_,_ in s.signal()}; s.wait() }
try! model.load()
func vec(_ t:String)->[Double]{ let r=try! model.embeddingResult(for:t,language:.korean)
    var s:[Double]=[];var n=0; r.enumerateTokenVectors(in:t.startIndex..<t.endIndex){v,_ in
    if s.isEmpty{s=[Double](repeating:0,count:v.count)}; for i in 0..<v.count{s[i]+=v[i]};n+=1;return true}
    for i in 0..<s.count{s[i]/=Double(n)}; return s }
func norm(_ a:[Double])->[Double]{let m=(a.reduce(0){$0+$1*$1}).squareRoot()+1e-9;return a.map{$0/m}}
func cos(_ a:[Double],_ b:[Double])->Double{zip(a,b).reduce(0){$0+$1.0*$1.1}}

let ref = ["날씨가 흐려서 우산을 챙겼다","회의가 길어져 피곤하다","새 책을 한 권 샀다",
           "커피를 마시며 음악을 들었다","오랜만에 친구에게 연락했다","영화를 보고 감동했다",
           "예산을 다시 계산했다","버스를 놓쳐서 뛰었다","정원에 물을 주었다","사진을 정리했다",
           "산책을 하며 생각을 정리했다","저녁 메뉴를 고민했다"]
let refVecs = ref.map(vec); let dim = refVecs[0].count
var C=[Double](repeating:0,count:dim); for v in refVecs{for i in 0..<dim{C[i]+=v[i]}}; for i in 0..<dim{C[i]/=Double(refVecs.count)}
func centered(_ v:[Double])->[Double]{ norm(zip(v,C).map{$0-$1}) }

let threshold = 0.1
let seq = ["오늘 수업 회고를 적었다","점심으로 김치찌개를 먹었다","수업이 끝나고 다시 생각했다",
           "저녁에 파스타를 해먹었다","주말에 등산을 다녀왔다","내일 학부모 상담 준비를 해야 한다"]
var themes: [[String]] = []        // 각 주제의 포착 텍스트
var themeVecs: [[[Double]]] = []   // 각 주제의 원본 임베딩들

for t in seq {
    let raw = vec(t); let target = centered(raw)
    var best = -2.0; var bestI = -1
    for (i,vs) in themeVecs.enumerated() {
        var mc=[Double](repeating:0,count:dim); for v in vs{for k in 0..<dim{mc[k]+=v[k]}}; for k in 0..<dim{mc[k]/=Double(vs.count)}
        let s = cos(target, centered(mc))
        print(String(format:"   \"%@\" vs 주제%d → %.3f", t.prefix(10).description, i, s))
        if s>best{best=s;bestI=i}
    }
    if best>threshold { themes[bestI].append(t); themeVecs[bestI].append(raw); print("  → 주제\(bestI)에 합류\n") }
    else { themes.append([t]); themeVecs.append([raw]); print("  → 새 주제\(themes.count-1)\n") }
}
print("=== 최종 주제 \(themes.count)개 ===")
for (i,ts) in themes.enumerated() { print("주제\(i): \(ts.map{$0.prefix(12)})") }
