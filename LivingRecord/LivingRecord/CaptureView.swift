import SwiftUI
import SwiftData

// S1 — 포착 화면. 결정 0개: 녹음 버튼 + 텍스트 폴백 + 끝. (분류 UI 없음)
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @State private var recorder = AudioRecorder()
    @State private var draft = ""
    @State private var status = ""
    private let transcriber: Transcriber = SpeechTranscriberImpl()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // 녹음 버튼 + 목소리에 반응하는 펄스 링
            ZStack {
                if recorder.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1 + recorder.level * 0.8)
                        .animation(.easeOut(duration: 0.08), value: recorder.level)
                }
                Button { Task { await toggleRecord() } } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 100)
                        .background(recorder.isRecording ? Color.red : Color.blue, in: Circle())
                }
                .accessibilityLabel(recorder.isRecording ? "녹음 정지 및 저장" : "녹음 시작")
            }

            // 진행 표시: 경과시간 + 레벨 미터  /  대기 안내
            if recorder.isRecording {
                Label(timeString(recorder.elapsed), systemImage: "record.circle")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, options: .repeating)
                Capsule()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 180, height: 8)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 180 * recorder.level, height: 8)
                            .animation(.easeOut(duration: 0.08), value: recorder.level)
                    }
                Text("듣고 있어요 · 탭하면 저장").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("탭해서 말하기").foregroundStyle(.secondary)
            }

            if !status.isEmpty && !recorder.isRecording {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(alignment: .bottom) {
                TextField("또는 직접 입력", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("저장") { saveText() }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func toggleRecord() async {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            status = "전사 중…"
            do {
                let text = try await transcriber.transcribe(audioURL: url)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { status = "인식 결과가 없어요" }
                else { save(trimmed); status = "저장됨 ✓" }
            } catch {
                status = "오류: \(error.localizedDescription)"
            }
        } else {
            do { try recorder.start(); status = "" }
            catch { status = "마이크 오류: \(error.localizedDescription)" }
        }
    }

    private func saveText() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        save(t)
        draft = ""
        status = "저장됨 ✓"
    }

    private func save(_ text: String) {
        context.insert(Capture(text: text))
        try? context.save()
    }
}
