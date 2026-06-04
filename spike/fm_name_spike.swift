// 스파이크 — FM 주제 이름짓기 + 휴리스틱(NLTagger) 폴백
import Foundation
import FoundationModels
import NaturalLanguage

func topNoun(_ text: String) -> String {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    var nouns: [String] = []
    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word,
                         scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, r in
        if tag == .noun { nouns.append(String(text[r])) }
        return true
    }
    return nouns.max(by: { $0.count < $1.count }) ?? String(text.prefix(12))
}

func fmName(_ text: String) async -> (name: String, via: String) {
    guard case .available = SystemLanguageModel.default.availability else {
        return (topNoun(text), "폴백(FM불가)")
    }
    do {
        let s = LanguageModelSession(instructions:
            "다음 한국어 메모의 핵심 주제를 2~6자 명사구 하나로만 답하라. 설명·문장부호 없이 라벨만.")
        let r = try await s.respond(to: text)
        let name = r.content.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n").first ?? ""
        return name.isEmpty ? (topNoun(text), "폴백(빈응답)") : (name, "FM")
    } catch {
        return (topNoun(text), "폴백(가드레일/에러)")
    }
}

let texts = [
    "오늘 수업 회고를 적었다",
    "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다고 생각했어.",
    "점심으로 김치찌개를 맛있게 먹었다",
]
let sem = DispatchSemaphore(value: 0)
Task {
    for t in texts {
        let (name, via) = await fmName(t)
        print("[\(via)] \"\(name)\"   ← \(t.prefix(24))")
    }
    sem.signal()
}
_ = sem.wait(timeout: .now() + 120)
