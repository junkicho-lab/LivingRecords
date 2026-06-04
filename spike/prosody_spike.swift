// 스파이크 — prosody 에너지(각성도) 추출 검증 (vDSP RMS → 0~1)
// 실행: swift prosody_spike.swift  (cap.wav 필요)
import Foundation
import AVFoundation
import Accelerate

func samples(_ url: URL) -> [Float]? {
    guard let file = try? AVAudioFile(forReading: url) else { return nil }
    let fmt = file.processingFormat
    guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(file.length)),
          (try? file.read(into: buf)) != nil, let ch = buf.floatChannelData?[0] else { return nil }
    return Array(UnsafeBufferPointer(start: ch, count: Int(buf.frameLength)))
}

// RMS dBFS → 0..1 (-50dB..0dB)
func energyScore(_ s: [Float]) -> Double {
    var rms: Float = 0
    vDSP_rmsqv(s, 1, &rms, vDSP_Length(s.count))
    let db = 20 * log10(max(Double(rms), 1e-7))
    return max(0, min(1, (max(db, -50) + 50) / 50))
}

guard let s = samples(URL(fileURLWithPath: "cap.wav")) else { print("❌ 읽기 실패"); exit(1) }
let loud = energyScore(s)
let quiet = energyScore(s.map { $0 * 0.1 })   // 음량 1/10 (조용히 말한 셈)
print(String(format: "원본 에너지:     %.3f", loud))
print(String(format: "1/10 음량 에너지: %.3f", quiet))
print(String(format: "\n차이 %.3f → %@", loud - quiet,
      loud - quiet > 0.1 ? "✅ 음량에 반응(각성도 신호 유효)" : "⚠️ 둔감"))
print("\n참고: 절대값보다 '내 평소 대비' 상대값으로 쓸 것(spike-findings ③ 메모).")
