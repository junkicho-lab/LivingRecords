import Foundation
let fillers: Set<String> = ["음","응","어","으","아","에","엄","흠","음음","어어","으음","에에"]
func clean(_ text: String) -> String {
    let tokens = text.split(whereSeparator: { $0==" " || $0=="\n" || $0=="\t" })
    let kept = tokens.filter { tok in
        let t = tok.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?…~·"))
        return !t.isEmpty && !fillers.contains(t)
    }
    let r = kept.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    return r.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : r
}
let tests = [
  "음 그러니까 이게 좀 애매한데 다시 생각해 봐야겠다",
  "응 오늘 수업은 잘 됐어",
  "어, 내일 상담 준비하자",
  "아 맞다 받아쓰기 점수 확인",
  "음",                              // 전부 필러 → 원문 유지
  "그 아이가 발표를 잘했다",          // '그'는 보존(의미)
]
for t in tests { print("\"\(t)\"\n  → \"\(clean(t))\"") }
