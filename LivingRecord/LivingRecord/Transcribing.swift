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
        // 한국어 전사 에셋 '구독(예약)' 보장 — 미예약 시 "not subscribed to transcription.ko"로 전사 실패.
        let reserved = await AssetInventory.reservedLocales
        if !reserved.contains(where: { $0.identifier(.bcp47).hasPrefix("ko") }) {
            _ = try? await AssetInventory.reserve(locale: locale)
        }
        if let req = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await req.downloadAndInstall()
        }
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
}
