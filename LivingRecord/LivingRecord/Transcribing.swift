import Foundation
import Speech
import AVFoundation

// S1 — 신형 SpeechTranscriber 기반 한국어 파일 전사 (spike/stt_new.swift 포팅).
// GOTCHA(실기기): 로케일 '예약(reserve)'이 성공해야 에셋을 구독한다. reserve는 Bool을 반환하므로
// try?로 삼키면 "not subscribed to transcription.ko"가 뒤늦게·원인 없이 터진다 → 결과를 확인하고 원인을 노출.
struct SpeechTranscriberImpl: Transcriber {
    enum STTError: LocalizedError {
        case unsupported
        case reserveFailed(reserved: [String], max: Int)
        var errorDescription: String? {
            switch self {
            case .unsupported:
                return "이 기기에서 한국어 음성 인식을 지원하지 않습니다."
            case .reserveFailed(let reserved, let max):
                return "음성 인식 에셋 예약 실패 (예약됨 \(reserved.count)/\(max): \(reserved.joined(separator: ", "))). 잠시 후 다시 시도해 주세요."
            }
        }
    }

    func transcribe(audioURL: URL) async throws -> String {
        let locale = Locale(identifier: "ko-KR")
        let transcriber = SpeechTranscriber(locale: locale,
                                            transcriptionOptions: [],
                                            reportingOptions: [],
                                            attributeOptions: [])

        // 1) 이 기기가 한국어 on-device 전사를 지원하나? (supportedLocales는 구독 불필요한 능력 목록)
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47).hasPrefix("ko") }) else {
            throw STTError.unsupported
        }

        // 2) 로케일 '예약(구독)' — 미예약 시 전사가 "not subscribed to transcription.ko"로 실패.
        //    reserve의 Bool·throw를 삼키지 않고 성공을 요구한다(실패 원인을 사용자에게 노출).
        let reserved = await AssetInventory.reservedLocales
        if !reserved.contains(where: { $0.identifier(.bcp47).hasPrefix("ko") }) {
            let ok = try await AssetInventory.reserve(locale: locale)
            if !ok {
                let now = await AssetInventory.reservedLocales.map { $0.identifier(.bcp47) }
                throw STTError.reserveFailed(reserved: now, max: AssetInventory.maximumReservedLocales)
            }
        }

        // 3) 에셋 설치(필요 시).
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
