import Foundation
import AVFoundation
import Accelerate

// S2 — prosody 에너지(각성도) 추출. spike/prosody_spike.swift 검증 코드 포팅.
// RMS 음량(dBFS)을 0~1로. 절대값보다 '평소 대비' 상대값으로 해석할 것.
struct ProsodyAnalyzerImpl: ProsodyAnalyzer {
    func energy(audioURL: URL) -> Double? {
        guard let file = try? AVAudioFile(forReading: audioURL) else { return nil }
        let fmt = file.processingFormat
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt,
                                         frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buf)) != nil,
              let ch = buf.floatChannelData?[0] else { return nil }
        var rms: Float = 0
        vDSP_rmsqv(ch, 1, &rms, vDSP_Length(buf.frameLength))
        let db = 20 * log10(max(Double(rms), 1e-7))           // dBFS
        return max(0, min(1, (max(db, -50) + 50) / 50))        // -50..0 dB → 0..1
    }
}
