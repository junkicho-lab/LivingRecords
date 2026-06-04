// 스파이크 — 앱 전체 파이프라인 재현(FM 이름짓기 + FM 배정)으로 과병합 원인/수정 확인
import Foundation
import FoundationModels
import NaturalLanguage

@Generable struct Pick { @Guide(description:"같은 주제 번호(0부터), 없으면 -1") let index: Int }

// 개선안: 주제 이름 = 행위가 아니라 '소재/분야'
func name(for memo:String) async -> String {
    guard case .available = SystemLanguageModel.default.availability else { return String(memo.prefix(8)) }
    do {
        let s = LanguageModelSession(instructions:
            "메모가 다루는 핵심 '소재·분야'를 2~5자 명사 하나로만 답하라. 행위·동작 말고 대상. 문장부호·설명 금지. 예) '수업 회고를 적었다'→'수업', '김치찌개를 먹었다'→'음식'.")
        let r = try await s.respond(to: memo)
        return r.content.trimmingCharacters(in: CharacterSet(charactersIn: " .。!?\n\"'·:")).components(separatedBy:"\n").first ?? "기타"
    } catch { return String(memo.prefix(8)) }
}
func assign(_ memo:String, _ names:[String]) async -> Int {
    guard !names.isEmpty else { return -1 }
    guard case .available = SystemLanguageModel.default.availability else { return -1 }
    let list = names.enumerated().map{"\($0.offset). \($0.element)"}.joined(separator:"\n")
    do {
        let s = LanguageModelSession(instructions:
            "메모의 소재가 기존 주제와 '같은 분야'면 그 번호, 다른 분야면 -1. 애매하면 -1(새 주제 선호).")
        let r = try await s.respond(to:"주제들:\n\(list)\n\n메모: \(memo)", generating: Pick.self)
        return r.content.index
    } catch { return -1 }
}

let seq = ["오늘 수업 회고를 적었다","점심으로 김치찌개를 먹었다","수업이 끝나고 다시 생각했다",
           "주말에 등산을 다녀왔다","체육대회 때 아이들 응원이 뜨거웠다"]
var names:[String]=[]; var members:[String:[String]]=[:]
let sem=DispatchSemaphore(value:0)
Task {
    for memo in seq {
        let idx = await assign(memo, names)
        if idx>=0 && idx<names.count { members[names[idx], default:[]].append(memo); print("  \"\(memo.prefix(14))\" → 기존 '\(names[idx])'") }
        else { let nm = await name(for: memo); names.append(nm); members[nm]=[memo]; print("  \"\(memo.prefix(14))\" → 새 주제 '\(nm)'") }
    }
    print("\n=== 주제 \(names.count)개 ===")
    for n in names { print("• \(n): \(members[n]!.map{$0.prefix(12)})") }
    sem.signal()
}
_ = sem.wait(timeout: .now()+200)
