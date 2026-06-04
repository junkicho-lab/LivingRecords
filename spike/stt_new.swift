// 스파이크 ②-new — 신형 SpeechTranscriber/SpeechAnalyzer 한국어 파일 전사
// 실행: swift stt_new.swift   (cap.wav 필요)
import Foundation
import Speech
import AVFoundation

let url = URL(fileURLWithPath: "cap.wav")
let expected = "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다고 생각했어."
let locale = Locale(identifier: "ko-KR")

func lev(_ a: [Character], _ b: [Character]) -> Int {
    var d = Array(0...b.count)
    for i in 1...a.count { var p = d[0]; d[0] = i
        for j in 1...b.count { let t = d[j]; d[j] = min(d[j]+1, d[j-1]+1, p + (a[i-1]==b[j-1] ?0:1)); p = t } }
    return d[b.count]
}

let sem = DispatchSemaphore(value: 0)
Task {
    do {
        let supported = await SpeechTranscriber.supportedLocales.map { $0.identifier(.bcp47) }
        let installed = await SpeechTranscriber.installedLocales.map { $0.identifier(.bcp47) }
        print("ko 지원? \(supported.contains { $0.hasPrefix("ko") }) / 설치됨? \(installed.contains { $0.hasPrefix("ko") })")

        let transcriber = SpeechTranscriber(locale: locale,
                                            transcriptionOptions: [],
                                            reportingOptions: [],
                                            attributeOptions: [])

        if let req = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            print("⬇️ 에셋 설치 중…")
            try await req.downloadAndInstall()
            print("설치 완료")
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: url)

        // 결과 수집 태스크
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

        let out = try await collect.value
        let e = Array(expected.replacingOccurrences(of: " ", with: ""))
        let g = Array(out.replacingOccurrences(of: " ", with: ""))
        let acc = 1.0 - Double(lev(e, g))/Double(max(e.count,1))
        print("\n기대: \(expected)\n인식: \(out)")
        print(String(format: "\n문자 정확도 ≈ %.1f%% → %@", acc*100,
              acc>0.9 ? "✅ 양호" : (acc>0.75 ? "🟡 보통" : "⚠️ 부족")))
    } catch {
        print("❌ \(error)")
    }
    sem.signal()
}
if sem.wait(timeout: .now() + 120) == .timedOut { print("⏱️ 타임아웃") }
