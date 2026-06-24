import Foundation
import FoundationModels
import NaturalLanguage

// S4b — 주제 이름짓기. Foundation Models 우선, 가드레일/불가 시 NLTagger 휴리스틱 폴백.
enum ThemeNamer {
    static func name(for text: String) async -> String {
        // FM→MLX 폴백 경유(LocalSynth). 둘 다 막히면 NLTagger 휴리스틱.
        if let r = await LocalSynth.generate(
            "메모가 다루는 핵심 주제를 짧은 명사구(2~10자) 하나로 붙여라. 막연한 한 단어('음식','일','생각')보다 무엇에 관한지 드러나는 구체적 이름을 선호한다. 행위 서술·문장·문장부호·설명 금지. 예) '발표 수업이 잘 됐다'→'발표 수업', '김치찌개를 끓였다'→'김치찌개', '러닝 페이스가 늘었다'→'러닝'.",
            text) {
            let n = clean(r)
            if !n.isEmpty { return n }
        }
        return fallback(text)
    }

    static func clean(_ s: String) -> String {
        var n = s.trimmingCharacters(in: .whitespacesAndNewlines)
        n = n.components(separatedBy: "\n").first ?? n
        n = n.trimmingCharacters(in: CharacterSet(charactersIn: " .。!?\"'`-·:"))
        return String(n.prefix(24))
    }

    static func fallback(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var nouns: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word,
                             scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, r in
            if tag == .noun { nouns.append(String(text[r])) }
            return true
        }
        return nouns.max(by: { $0.count < $1.count })
            ?? String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
    }
}
