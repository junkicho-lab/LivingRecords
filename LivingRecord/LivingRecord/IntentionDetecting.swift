import Foundation
import FoundationModels

// S8 — 자동 의도 감지. 스파이크 ⑦: FM Bool 판정은 yes 쏠림으로 불안정(1~6/10) → 판정은 결정적 어미 게이트(10/10),
// FM은 의도구(라벨) 추출에만 best-effort(실패·빈값·과장 시 포착 텍스트 폴백). 가드레일·지연·번들 0.
struct IntentionDetectorImpl: IntentionDetector {
    // 한국어 의도·다짐 어미/표현(보수적 substring). 합성 자모(ㄹ까 등)는 실텍스트에 없으니 실제 음절형만.
    static let markers = [
        "겠", "해야", "하자", "해보자", "해 보자", "볼까", "할까", "을까", "ㄹ까",
        "봐야지", "야지", "려고", "을래", "를래", "시작하", "기로 했", "기로 함", "다짐", "마음먹",
    ]

    func hasIntention(_ text: String) -> Bool {
        Self.markers.contains { text.contains($0) }
    }

    func extractPhrase(_ text: String) async -> String {
        // FM→MLX 폴백 경유. 빈값·장황·둘 다 막힘이면 텍스트 앞부분 폴백.
        guard let r = await LocalSynth.generate(
            "다음 메모에서 화자가 '하겠다'고 한 행동을 짧은 한국어 명사구로만 뽑아라. 설명·문장 말고 구절만. 예: '아침 글쓰기'.",
            text) else { return fallback(text) }
        return (r.isEmpty || r.count > 30) ? fallback(text) : r
    }

    private func fallback(_ t: String) -> String {
        String(t.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20))
    }
}
