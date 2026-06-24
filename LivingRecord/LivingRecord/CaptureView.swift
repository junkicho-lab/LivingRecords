import SwiftUI
import SwiftData

// S1/S2 — 포착 화면. 결정 0개: 녹음+텍스트 폴백. S2: 에너지 추출 + 봉인 토글.
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Environment(CloudConsent.self) private var consent     // 클라우드 분류 옵트인 여부
    @Environment(AppLaunchState.self) private var launch    // S12 — 트리거 자동 녹음
    @State private var recorder = AudioRecorder()
    @State private var draft = ""
    @State private var status = ""
    @State private var sealNext = false        // 봉인 모드(음성·텍스트 공통)
    @FocusState private var draftFocused: Bool
    @State private var showSettings = false
    @State private var echoes: [Capture] = []     // 포착 순간 연결: 방금 적은 것과 비슷한 옛 생각
    private let transcriber: Transcriber = SpeechTranscriberImpl()
    private let prosody: ProsodyAnalyzer = ProsodyAnalyzerImpl()

    var body: some View {
        NavigationStack {
        VStack(spacing: 20) {
            // 봉인 토글
            Button { sealNext.toggle() } label: {
                Label(sealNext ? "봉인 모드 — 이 기록은 기기 밖으로 안 나가요" : "봉인",
                      systemImage: sealNext ? "lock.fill" : "lock.open")
                    .font(.subheadline)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(sealNext ? Color.purple.opacity(0.15) : Color.gray.opacity(0.12),
                                in: Capsule())
                    .foregroundStyle(sealNext ? .purple : .secondary)
            }
            .padding(.top, 8)

            Spacer()

            // 녹음 버튼 + 목소리에 반응하는 펄스 링
            ZStack {
                if recorder.isRecording {
                    Circle()
                        .fill((sealNext ? Color.purple : Color.red).opacity(0.18))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1 + recorder.level * 0.8)
                        .animation(.easeOut(duration: 0.08), value: recorder.level)
                }
                Button { Task { await toggleRecord() } } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill"
                          : (sealNext ? "lock.fill" : "mic.fill"))
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 100)
                        .background(recorder.isRecording ? (sealNext ? Color.purple : Color.red)
                                    : (sealNext ? Color.purple : Color.blue), in: Circle())
                }
                .accessibilityLabel(recorder.isRecording ? "녹음 정지 및 저장" : "녹음 시작")
            }

            if recorder.isRecording {
                Label(timeString(recorder.elapsed), systemImage: "record.circle")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(sealNext ? .purple : .red)
                    .symbolEffect(.pulse, options: .repeating)
                Capsule()
                    .fill((sealNext ? Color.purple : Color.red).opacity(0.2))
                    .frame(width: 180, height: 8)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(sealNext ? Color.purple : Color.red)
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

            if !echoes.isEmpty && !recorder.isRecording {
                VStack(alignment: .leading, spacing: 6) {
                    Label("예전에 비슷한 생각", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(echoes) { e in
                        HStack(alignment: .top, spacing: 6) {
                            Text("·").foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(e.text).font(.caption).lineLimit(2)
                                Text(e.createdAt, format: .dateTime.year().month().day())
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onTapGesture { withAnimation { echoes = [] } }
                .transition(.opacity)
            }

            Spacer()

            HStack(alignment: .bottom) {
                TextField("또는 직접 입력", text: $draft, axis: .vertical)
                    .lineLimit(1...6)   // 줄바꿈/긴 글이면 1~6줄까지 아래로 늘어남
                    .fixedSize(horizontal: false, vertical: true)   // 세로 압축 방지 → 본문 높이만큼 확장
                    .focused($draftFocused)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray3)))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("완료") { draftFocused = false }
                        }
                    }
                Button("저장") { saveText() }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
            }
        }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onChange(of: launch.startCapture) { _, requested in
            if requested { Task { await handleLaunchCapture() } }
        }
        .onAppear { Task { await handleLaunchCapture() } }   // 콜드 런치 대비
    }

    // S12 — App Intent/액션버튼/Siri 트리거로 들어오면 봉인 모드 맞추고 바로 녹음 시작.
    private func handleLaunchCapture() async {
        guard launch.startCapture else { return }
        sealNext = launch.startSealed
        launch.startCapture = false        // 소비(중복 방지)
        if !recorder.isRecording { await toggleRecord() }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func toggleRecord() async {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            let energy = prosody.energy(audioURL: url)   // 폐기 전에 점수만 추출(절충안 C)
            let sealed = sealNext
            status = "전사 중…"
            do {
                let text = try await transcriber.transcribe(audioURL: url)
                let trimmed = FillerCleaner.clean(text)   // 추임새 가벼운 정리(음성만)
                if trimmed.isEmpty { flashStatus("인식 결과가 없어요") }
                else {
                    save(trimmed, energy: energy, sealed: sealed)
                    flashStatus(sealed ? "봉인 저장됨 🔒" : "저장됨 ✓")
                }
            } catch {
                status = "오류: \(error.localizedDescription)"
            }
            try? FileManager.default.removeItem(at: url)  // 오디오 원본 폐기
        } else {
            do { try recorder.start(); status = ""; echoes = [] }
            catch { status = "마이크 오류: \(error.localizedDescription)" }
        }
    }

    private func saveText() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        save(t, energy: nil, sealed: sealNext)
        draft = ""
        draftFocused = false        // 저장 후 키보드 내림
        flashStatus(sealNext ? "봉인 저장됨 🔒" : "저장됨 ✓")
    }

    // 상태 메시지를 잠깐 보여주고 자동으로 지움(그 사이 새 메시지가 오면 유지).
    private func flashStatus(_ msg: String) {
        status = msg
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if status == msg { status = "" }
        }
    }

    private func save(_ text: String, energy: Double?, sealed: Bool) {
        let c = Capture(text: text, energy: energy, sealed: sealed)
        context.insert(c)
        try? context.save()
        Consolidator.enqueue(c, context: context, vault: vault, consent: consent)  // 통합 후 Obsidian 미러(주제 [[링크]] 포함)
        showEcho(for: text, excluding: c)
    }

    // 포착 순간 연결 — 방금 적은 것과 의미가 가까운 옛 포착을 조용히 띄움(의미 검색 재활용).
    // 방금 저장한 건 아직 임베딩 전(nil)이라 자동 제외됨. 봉인은 메아리에서 빼 사적 보호.
    private func showEcho(for text: String, excluding new: Capture) {
        let all = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        let pool = all.filter { $0.id != new.id && !$0.sealed }
        let hits = SemanticSearch.similar(to: text, in: pool, limit: 2)
        withAnimation { echoes = hits }
    }
}
