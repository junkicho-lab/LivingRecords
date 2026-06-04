import Foundation
import AVFoundation
import Observation

// S1 — 마이크 녹음 + 실시간 음량/경과시간(녹음 진행 피드백).
@MainActor
@Observable
final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private(set) var isRecording = false
    private(set) var fileURL: URL?
    private(set) var level: Double = 0        // 0...1 현재 음량(목소리에 반응)
    private(set) var elapsed: TimeInterval = 0 // 경과 초

    func start() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cap-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
        ]
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)
        #endif
        let r = try AVAudioRecorder(url: url, settings: settings)
        r.isMeteringEnabled = true
        r.record()
        recorder = r; fileURL = url; isRecording = true
        elapsed = 0; level = 0

        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                guard let rec = self.recorder else { return }
                rec.updateMeters()
                let power = Double(rec.averagePower(forChannel: 0)) // dBFS (~ -160...0)
                self.level = max(0, (max(power, -50) + 50) / 50)    // -50dB..0dB → 0..1
                self.elapsed = rec.currentTime
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    @discardableResult
    func stop() -> URL? {
        timer?.invalidate(); timer = nil
        recorder?.stop()
        isRecording = false
        level = 0
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        return fileURL
    }
}
