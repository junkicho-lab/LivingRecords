import Foundation
import FoundationModels

// post-v4 — 로컬 LLM 텍스트 생성 통합 + 폴백 자리(seam). concept §3-11: "Apple FM + MLX 폴백" 이중화.
// FM 가드레일이 무해한 교사·아동 문장을 거짓 차단하면(spike ③) secondary(MLX 등)로 넘긴다.
// 텍스트 생성(이름짓기·일일/주간/기간 서술·증류 요약·의도구)이 여기로 모인다. (guided Bool 배정은 별개)
protocol TextSynth {
    var isAvailable: Bool { get }
    func generate(instruction: String, input: String) async -> String?
}

// Apple Foundation Models. 가드레일/에러는 nil로 → 폴백 기회를 준다.
struct FMSynth: TextSynth {
    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }
    func generate(instruction: String, input: String) async -> String? {
        guard isAvailable else { return nil }
        do {
            let s = LanguageModelSession(instructions: instruction)
            let t = try await s.respond(to: input).content.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        } catch { return nil }   // 가드레일/에러 → 폴백
    }
}

enum LocalSynth {
    // MLX 등 2차 합성기. 패키지·모델 준비되면 앱 시작 시 주입(없으면 FM만).
    static var secondary: TextSynth?

    // FM 먼저 → 실패/차단 시 secondary → 둘 다 없으면 nil(호출부가 결정적 폴백).
    static func generate(_ instruction: String, _ input: String) async -> String? {
        if let r = await FMSynth().generate(instruction: instruction, input: input) { return r }
        if let s = secondary, s.isAvailable,
           let r = await s.generate(instruction: instruction, input: input) { return r }
        return nil
    }
}
