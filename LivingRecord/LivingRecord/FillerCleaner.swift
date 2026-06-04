import Foundation

// 다듬기 — 음성 받아쓰기의 추임새(filler) 가벼운 정리. 명백한 간투사만 보수적으로 제거.
enum FillerCleaner {
    // 단독 토큰일 때만 제거. 의미 가능성 있는 '그/이제/뭐/저' 등은 일부러 제외(보수적).
    private static let fillers: Set<String> = [
        "음", "응", "어", "으", "아", "에", "엄", "흠", "음음", "어어", "으음", "에에",
    ]

    /// 공백 단위로 나눠 명백한 간투사 토큰을 제거. 전부 필러면 원문 유지.
    static func clean(_ text: String) -> String {
        let tokens = text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
        let kept = tokens.filter { tok in
            let t = tok.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?…~·"))
            return !t.isEmpty && !fillers.contains(t)
        }
        let result = kept.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : result
    }
}
