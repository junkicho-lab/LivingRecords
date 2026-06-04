// 스파이크 — FM 구조화 출력(guided)로 주제 배정 (깨끗한 주제명 + 번호 강제)
import Foundation
import FoundationModels

@Generable
struct Choice {
    @Guide(description: "메모가 명확히 같은 주제면 그 번호(0부터), 어디에도 안 맞으면 -1")
    let index: Int
}

func assign(_ memo: String, themes: [String]) async -> Int {
    guard case .available = SystemLanguageModel.default.availability else { return -1 }
    let list = themes.enumerated().map { "\($0.offset). \($0.element)" }.joined(separator: "\n")
    do {
        let s = LanguageModelSession(instructions:
            "메모를 기존 주제 중 하나에 배정한다. 명확히 같은 주제가 있으면 그 번호, 없으면 -1.")
        let r = try await s.respond(to: "주제들:\n\(list)\n\n메모: \(memo)", generating: Choice.self)
        return r.content.index
    } catch { return -2 }   // -2 = 가드레일/에러
}

let themes = ["수업·교육", "음식·식사"]
let tests = [
    ("수업이 끝나고 다시 생각했다", 0),
    ("저녁에 파스타를 해먹었다", 1),
    ("주말에 등산을 다녀왔다", -1),
    ("내일 학부모 상담 준비를 해야 한다", 0),   // 교육 맥락(0) 또는 -1 가능
    ("체육대회 때 아이들 응원이 뜨거웠다", 0),
    ("점심 메뉴로 뭘 먹을지 고민이다", 1),
]
let sem = DispatchSemaphore(value: 0)
Task {
    for (memo, expect) in tests {
        let got = await assign(memo, themes: themes)
        let mark = got == expect ? "✅" : (got == -2 ? "🛑가드레일" : "❓")
        print("\(mark) got=\(got) expect=\(expect)  | \(memo.prefix(20))")
    }
    sem.signal()
}
_ = sem.wait(timeout: .now() + 180)
