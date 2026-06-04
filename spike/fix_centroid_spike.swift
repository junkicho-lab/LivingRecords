// 스파이크 — 고정 참조 centroid로 중심화하면 소수(3개)에서도 통합되는가?
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

// 다양한 한국어 참조 세트(주제와 무관) → 고정 중심 벡터
let ref = ["날씨가 흐려서 우산을 챙겼다","회의가 길어져 피곤하다","새 책을 한 권 샀다",
           "커피를 마시며 음악을 들었다","오랜만에 친구에게 연락했다","영화를 보고 감동했다",
           "예산을 다시 계산했다","버스를 놓쳐서 뛰었다","정원에 물을 주었다","사진을 정리했다"]
let refVecs = ref.map(vec)
let dim = refVecs[0].count
var centroid=[Double](repeating:0,count:dim)
for v in refVecs{for i in 0..<dim{centroid[i]+=v[i]}}; for i in 0..<dim{centroid[i]/=Double(refVecs.count)}
func centered(_ v:[Double])->[Double]{ norm(zip(v,centroid).map{$0-$1}) }

// 문제의 3개만(소수 상황 재현)
let A1=centered(vec("오늘 수업 회고를 적었다"))
let A2=centered(vec("수업이 끝나고 다시 생각했다"))
let B = centered(vec("점심으로 김치찌개를 먹었다"))
print(String(format:"cos(수업1,수업2) = %.3f  ← 높아야(합쳐짐)", cos(A1,A2)))
print(String(format:"cos(수업1,음식)  = %.3f", cos(A1,B)))
print(String(format:"cos(수업2,음식)  = %.3f", cos(A2,B)))
let ok = cos(A1,A2) > 0.1 && cos(A1,A2) > cos(A1,B) && cos(A1,A2) > cos(A2,B)
print("\n판정: \(ok ? "✅ 고정 참조 중심화 → 소수에서도 수업끼리 묶임" : "⚠️ 여전히 분리")")
