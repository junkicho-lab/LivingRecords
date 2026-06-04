import SwiftUI

// 다듬기 — 실기기 실음성 받아쓰기 정확도(CER) 측정 도구. 기준 문장을 읽고 인식 결과와 비교.
struct STTAccuracyView: View {
    private let references = [
        "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있었다",
        "내일 학부모 상담 자료를 미리 준비해야겠다",
        "받아쓰기 시험 점수가 지난번보다 조금 올랐다",
        "체육대회 응원 연습을 점심시간에 했다",
        "이 활동은 다음 학기에도 계속 이어가고 싶다",
        "음 그러니까 이게 좀 애매한데 다시 한번 생각해 봐야 할 것 같다",
    ]
    @State private var idx = 0
    @State private var recorder = AudioRecorder()
    @State private var status = ""
    @State private var results: [(ref: String, hyp: String, cer: Double)] = []
    private let transcriber: Transcriber = SpeechTranscriberImpl()

    var body: some View {
        List {
            Section("읽을 문장 (\(idx + 1)/\(references.count))") {
                Text(references[idx]).font(.title3)
                Button { Task { await toggle() } } label: {
                    Label(recorder.isRecording ? "정지 & 측정" : "읽고 녹음",
                          systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .foregroundStyle(recorder.isRecording ? .red : .blue)
                }
                if recorder.isRecording {
                    Text(String(format: "녹음 중… 레벨 %.0f%%", recorder.level * 100))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary) }
            }

            if let last = results.last {
                Section("최근 결과") {
                    labeled("기준", last.ref)
                    labeled("인식", last.hyp.isEmpty ? "(없음)" : last.hyp)
                    Text(String(format: "문자 정확도 %.1f%%  (오류율 %.1f%%)", (1 - last.cer) * 100, last.cer * 100))
                        .bold().foregroundStyle((1 - last.cer) > 0.85 ? .green : .orange)
                }
            }

            if !results.isEmpty {
                Section("누적 \(results.count)건") {
                    let avg = results.map { 1 - $0.cer }.reduce(0, +) / Double(results.count)
                    Text(String(format: "평균 문자 정확도 %.1f%%", avg * 100)).bold()
                    Button("결과 초기화", role: .destructive) { results.removeAll() }
                }
            }
        }
        .navigationTitle("받아쓰기 정확도")
        .toolbar {
            Button("다음 문장") {
                idx = (idx + 1) % references.count
                status = ""
            }
        }
    }

    private func labeled(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(k).font(.caption).foregroundStyle(.secondary)
            Text(v)
        }
    }

    private func toggle() async {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            status = "인식 중…"
            do {
                let hyp = try await transcriber.transcribe(audioURL: url)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let cer = charErrorRate(reference: references[idx], hypothesis: hyp)
                results.append((references[idx], hyp, cer))
                status = ""
                try? FileManager.default.removeItem(at: url)
            } catch {
                status = "오류: \(error.localizedDescription)"
            }
        } else {
            do { try recorder.start(); status = "" }
            catch { status = "마이크 오류: \(error.localizedDescription)" }
        }
    }

    // 공백 제외 문자 단위 오류율(CER) = 편집거리 / 기준 길이
    private func charErrorRate(reference: String, hypothesis: String) -> Double {
        let r = Array(reference.replacingOccurrences(of: " ", with: ""))
        let h = Array(hypothesis.replacingOccurrences(of: " ", with: ""))
        guard !r.isEmpty else { return h.isEmpty ? 0 : 1 }
        return min(1, Double(levenshtein(r, h)) / Double(r.count))
    }

    private func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }; if b.isEmpty { return a.count }
        var d = Array(0...b.count)
        for i in 1...a.count {
            var prev = d[0]; d[0] = i
            for j in 1...b.count {
                let t = d[j]
                d[j] = Swift.min(d[j] + 1, d[j - 1] + 1, prev + (a[i - 1] == b[j - 1] ? 0 : 1))
                prev = t
            }
        }
        return d[b.count]
    }
}
