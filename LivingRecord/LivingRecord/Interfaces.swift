import Foundation

// S0 — 컴포넌트 경계 추상화(concept.md §3-11 "관통 원칙"). 슬라이스 진행하며 실제 구현으로 교체.

protocol Transcriber {                              // STT (S1, SpeechTranscriber)
    func transcribe(audioURL: URL) async throws -> String
}
protocol ProsodyAnalyzer {                          // 에너지 점수 (S2, vDSP)
    func energy(audioURL: URL) -> Double?
}
protocol Embedder {                                 // 임베딩 (S4, NLContextualEmbedding + 중심화)
    func embed(_ text: String) -> [Double]?
}
protocol LocalSynthesizer {                         // 로컬 LLM (S4/S5, Foundation Models + MLX 폴백)
    func suggestTags(for text: String) async throws -> [String]
    func summarize(_ texts: [String], instruction: String) async throws -> String
}
protocol DeepSynthesizer {                          // 클라우드 깊은 종합 (S6, Claude)
    func synthesize(distilled: String, instruction: String) async throws -> String
}
protocol ObsidianMirror {                           // 마크다운 미러 (S3, 단방향, 봉인 제외)
    func mirror(_ capture: Capture) throws
    func mirror(_ digest: Digest) throws
}

// --- S0 스텁 (no-op) ---
struct StubTranscriber: Transcriber {
    func transcribe(audioURL: URL) async throws -> String { "" }
}
struct StubProsody: ProsodyAnalyzer {
    func energy(audioURL: URL) -> Double? { nil }
}
struct StubEmbedder: Embedder {
    func embed(_ text: String) -> [Double]? { nil }
}
struct StubLocalSynthesizer: LocalSynthesizer {
    func suggestTags(for text: String) async throws -> [String] { [] }
    func summarize(_ texts: [String], instruction: String) async throws -> String { "" }
}
struct StubDeepSynthesizer: DeepSynthesizer {
    func synthesize(distilled: String, instruction: String) async throws -> String { "" }
}
struct StubObsidianMirror: ObsidianMirror {
    func mirror(_ capture: Capture) throws {}
    func mirror(_ digest: Digest) throws {}
}
