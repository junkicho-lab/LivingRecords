// 스파이크 — 번호 대신 '같은 분야?' Bool 판단(index 편향 회피)
import Foundation
import FoundationModels

@Generable struct Same {
    @Guide(description: "메모가 이 주제와 같은 분야·소재면 true, 다르면 false. 확실하지 않으면 false.")
    let same: Bool
}

func sameTopic(_ memo: String, _ theme: String) async -> Bool {
    guard case .available = SystemLanguageModel.default.availability else { return false }
    do {
        let s = LanguageModelSession(instructions:
            "메모가 주어진 주제와 '같은 분야/소재'인지 판단한다. 분야가 다르면 false. 애매하면 false.")
        let r = try await s.respond(to: "주제: \(theme)\n메모: \(memo)", generating: Same.self)
        return r.content.same
    } catch { return false }
}

let theme = "수업"
let tests: [(String, Bool)] = [
    ("수업이 끝나고 다시 생각했다", true),
    ("점심으로 김치찌개를 먹었다", false),
    ("주말에 등산을 다녀왔다", false),
    ("체육대회 때 아이들 응원이 뜨거웠다", true),   // 학교 행사 → 같은 분야 가능
    ("내일 학부모 상담 준비", true),
    ("새 운동화를 샀다", false),
]
let sem = DispatchSemaphore(value: 0)
Task {
    for (memo, expect) in tests {
        let got = await sameTopic(memo, theme)
        print("\(got == expect ? "✅" : "❓") same=\(got) (기대 \(expect))  | '\(theme)' ← \(memo.prefix(20))")
    }
    sem.signal()
}
_ = sem.wait(timeout: .now() + 120)
