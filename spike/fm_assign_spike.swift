// 스파이크 — FM 기반 주제 배정(임베딩 임계값 대신 의미 이해)
import Foundation
import FoundationModels

func assign(_ memo: String, themes: [String]) async -> String {
    guard case .available = SystemLanguageModel.default.availability else { return "새 주제" }
    let list = themes.isEmpty ? "(없음)" : themes.joined(separator: ", ")
    do {
        let s = LanguageModelSession(instructions:
            "너는 생각 메모를 주제별로 분류한다. 기존 주제 목록 중 새 메모가 명확히 같은 주제면 그 주제명을 '정확히 그대로' 답하라. 어디에도 안 맞으면 '새 주제'라고만 답하라. 다른 말 금지.")
        let r = try await s.respond(to: "기존 주제: \(list)\n메모: \(memo)")
        return r.content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch { return "새 주제(폴백)" }
}

let seq = ["오늘 수업 회고를 적었다","점심으로 김치찌개를 먹었다","수업이 끝나고 다시 생각했다",
           "저녁에 파스타를 해먹었다","주말에 등산을 다녀왔다","내일 학부모 상담 준비를 해야 한다",
           "체육대회 때 아이들 응원이 뜨거웠다"]
// 단순화: 주제명 = 그 주제 첫 메모의 짧은 라벨(여기선 수동 라벨로 진행 흐름만 검증)
var themeLabels: [String] = []
var members: [String:[String]] = [:]

let sem = DispatchSemaphore(value: 0)
Task {
    for memo in seq {
        let ans = await assign(memo, themes: themeLabels)
        let matched = themeLabels.first { ans.contains($0) || $0.contains(ans) }
        if let m = matched {
            members[m, default: []].append(memo)
            print("  \"\(memo.prefix(16))\" → 기존 '\(m)'")
        } else {
            let label = String(memo.prefix(10))   // 실제 앱은 ThemeNamer로 이름
            themeLabels.append(label); members[label] = [memo]
            print("  \"\(memo.prefix(16))\" → 새 주제 '\(label)'  (FM답:\(ans.prefix(12)))")
        }
    }
    print("\n=== 최종 주제 \(themeLabels.count)개 ===")
    for l in themeLabels { print("• \(l): \(members[l]!.map{$0.prefix(12)})") }
    sem.signal()
}
_ = sem.wait(timeout: .now() + 180)
