import Foundation

// S0 — 컴포넌트 경계 추상화(concept.md §3-11 "관통 원칙"). 실제 구현(*Impl)이 conform.
// (로컬 LLM 텍스트 생성은 LocalSynth, 클라우드는 CloudSynthesizer로 직접 구현 — 별도 프로토콜 불필요)

protocol Transcriber {                              // STT (S1, SpeechTranscriber)
    func transcribe(audioURL: URL) async throws -> String
}
protocol ProsodyAnalyzer {                          // 에너지 점수 (S2, vDSP)
    func energy(audioURL: URL) -> Double?
}
protocol Embedder {                                 // 임베딩 (S4, NLContextualEmbedding + 중심화)
    func embed(_ text: String) -> [Double]?
    func centeringVector() -> [Double]?             // 고정 참조 중심 벡터(anisotropy 보정용)
}
protocol ObsidianMirror {                           // 마크다운 미러 (S3, 단방향, 봉인 제외)
    func mirror(_ capture: Capture) throws
    func mirror(_ digest: Digest) throws
}
protocol IntentionDetector {                        // 의도 감지 (S8): 판정=결정적 어미, 라벨=FM best-effort
    func hasIntention(_ text: String) -> Bool
    func extractPhrase(_ text: String) async -> String
}
