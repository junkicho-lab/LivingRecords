import Foundation
import Speech
import AVFoundation

// S1 — 신형 SpeechTranscriber 기반 한국어 파일 전사 (spike/stt_new.swift 포팅).
struct SpeechTranscriberImpl: Transcriber {
    func transcribe(audioURL: URL) async throws -> String {
        let locale = Locale(identifier: "ko-KR")
        let transcriber = SpeechTranscriber(locale: locale,
                                            transcriptionOptions: [],
                                            reportingOptions: [],
                                            attributeOptions: [])
        try await ensureKoreanReady(transcriber, locale: locale)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: audioURL)

        let collect = Task { () -> String in
            var text = ""
            for try await r in transcriber.results { text += String(r.text.characters) }
            return text
        }
        if let last = try await analyzer.analyzeSequence(from: audioFile) {
            try await analyzer.finalizeAndFinish(through: last)
        } else {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        return try await collect.value
    }

    // 한국어 전사 준비: 에셋 '설치' → '예약(구독)' 순서를 보장한다.
    // 이전 버그: 예약을 설치보다 먼저 호출 → 미설치 로케일이라 예약 실패(try?로 삼켜짐) →
    //            미구독 상태로 전사가 진행돼 "예약됨 0/5" 에러가 표면화됐다. (spike/stt_new.swift는 설치만으로 동작)
    private func ensureKoreanReady(_ transcriber: SpeechTranscriber, locale: Locale) async throws {
        // 1) 에셋 설치 먼저 — 예약은 '설치된' 로케일에만 가능하다.
        if let req = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await req.downloadAndInstall()
        }
        // 2) 한국어 예약 보장 — 미예약 시 "not subscribed to transcription.ko"로 전사 실패.
        //    설치/부팅 직후엔 일시적으로 "예약됨 0/5"로 실패할 수 있어 짧게 재시도한다.
        for attempt in 0..<3 {
            if await AssetInventory.reservedLocales.contains(where: { $0.identifier(.bcp47).hasPrefix("ko") }) {
                return
            }
            do {
                _ = try await AssetInventory.reserve(locale: locale)
                return
            } catch {
                if attempt == 2 { throw error }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}
