// 스파이크 ② — 한국어 STT (SFSpeechRecognizer, on-device)
// 실행: swift stt_spike.swift   (cap.aiff 필요)
import Foundation
import Speech

let url = URL(fileURLWithPath: "cap.wav")
let expected = "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다고 생각했어."

// 권한 (CLI에선 막힐 수 있음 → 타임아웃)
let auth = DispatchSemaphore(value: 0)
SFSpeechRecognizer.requestAuthorization { status in
    print("권한 상태(raw=\(status.rawValue), 3=authorized): \(status)")
    auth.signal()
}
if auth.wait(timeout: .now() + 12) == .timedOut {
    print("⏱️ 권한 콜백 무응답 → CLI 권한 한계. 실제 앱(Info.plist+TCC)에서 검증 필요"); exit(2)
}
guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
    print("❌ 권한 없음 → CLI에서 막힘. 실제 앱 컨텍스트에서 검증 필요"); exit(2)
}

guard let rec = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")) else {
    print("❌ 한국어 recognizer 생성 불가"); exit(1)
}
print("⭐ 한국어 on-device 지원? \(rec.supportsOnDeviceRecognition)")

let req = SFSpeechURLRecognitionRequest(url: url)
req.requiresOnDeviceRecognition = true
req.taskHint = .dictation

let done = DispatchSemaphore(value: 0)
var finalText = ""
rec.recognitionTask(with: req) { result, error in
    if let error = error { print("❌ 인식 에러: \(error.localizedDescription)"); done.signal(); return }
    guard let result = result else { return }
    finalText = result.bestTranscription.formattedString
    print("  …부분: \(finalText)\(result.isFinal ? "  [FINAL]" : "")")
    if result.isFinal { done.signal() }
}
if done.wait(timeout: .now() + 55) == .timedOut {
    print("⏱️ 최종 미도달 — 위 마지막 부분 결과로 평가(첫 실행 모델 로딩 영향 가능)")
}
if finalText.isEmpty { print("⚠️ 결과 없음"); exit(3) }

// 대략적 문자 정확도(공백 제거 후 Levenshtein 기반)
func lev(_ a: [Character], _ b: [Character]) -> Int {
    var d = Array(0...b.count)
    for i in 1...a.count {
        var prev = d[0]; d[0] = i
        for j in 1...b.count {
            let t = d[j]; d[j] = min(d[j]+1, d[j-1]+1, prev + (a[i-1]==b[j-1] ? 0:1)); prev = t
        }
    }
    return d[b.count]
}
let e = Array(expected.replacingOccurrences(of: " ", with: ""))
let g = Array(finalText.replacingOccurrences(of: " ", with: ""))
let dist = lev(e, g)
let acc = 1.0 - Double(dist)/Double(max(e.count,1))
print("\n기대: \(expected)")
print("인식: \(finalText)")
print(String(format: "\n문자 정확도 ≈ %.1f%% (편집거리 %d/%d) → %@", acc*100, dist, e.count,
      acc > 0.9 ? "✅ 양호" : (acc > 0.75 ? "🟡 보통" : "⚠️ 부족 → WhisperKit 검토")))
