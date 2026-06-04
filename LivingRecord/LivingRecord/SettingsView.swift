import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// S3/S6b — Obsidian 볼트 + 클라우드 깊은 종합 설정.
struct SettingsView: View {
    @Environment(VaultStore.self) private var vault
    @Environment(CloudConsent.self) private var cloud
    @Environment(ReminderStore.self) private var reminders
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Transmission.date, order: .reverse) private var transmissions: [Transmission]
    @State private var picking = false
    @State private var keyDraft = ""
    // 백업/복원
    @State private var pass = ""
    @State private var askingExportPass = false
    @State private var askingImportPass = false
    @State private var showExport = false
    @State private var importingBackup = false
    @State private var exportDoc: BackupDocument?
    @State private var pendingImportURL: URL?
    @State private var backupMessage: String?
    @State private var syncMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let u = vault.vaultURL {
                        Label(u.lastPathComponent, systemImage: "folder.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("아직 선택 안 됨").foregroundStyle(.secondary)
                    }
                    Button(vault.vaultURL == nil ? "볼트 폴더 선택" : "볼트 폴더 변경") {
                        picking = true
                    }
                    if vault.vaultURL != nil {
                        Button { syncMessage = "다시 내보내는 중…"; let n = ObsidianSync.reexportAll(context: context, vault: vault); syncMessage = "\(n)개 다시 내보냈어요." } label: {
                            Label("전체 다시 내보내기", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button { syncMessage = ObsidianSync.pull(context: context, vault: vault).message } label: {
                            Label("Obsidian에서 가져오기", systemImage: "arrow.down.doc")
                        }
                        Toggle("앱 켤 때 자동 가져오기", isOn: Binding(get: { vault.bidirectional }, set: { vault.bidirectional = $0 }))
                        if let m = syncMessage { Text(m).font(.caption).foregroundStyle(.secondary) }
                    }
                } header: {
                    Text("Obsidian 볼트")
                } footer: {
                    Text("포착이 Captures 하위에 마크다운으로 미러됩니다(봉인은 '봉인' 폴더). 양방향: Obsidian에서 편집·추가·삭제한 내용을 '가져오기'로 앱에 반영해요(가져올 땐 Obsidian 우선, 삭제는 미러된 기록만). 새 볼트를 연결하면 '전체 다시 내보내기'를 먼저 하세요.")
                }

                Section {
                    Toggle("깊은 종합에 클라우드 사용", isOn: Binding(get: { cloud.enabled }, set: { cloud.enabled = $0 }))
                    SecureField("Claude API 키", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Button("키 저장") { cloud.setAPIKey(keyDraft); keyDraft = "" }
                            .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                        Spacer()
                        if cloud.hasAPIKey {
                            Label("저장됨", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.caption)
                            Button("삭제", role: .destructive) { cloud.setAPIKey("") }.font(.caption)
                        }
                    }
                } header: {
                    Text("클라우드 깊은 종합 (주간)")
                } footer: {
                    Text("켜면 주간 정리를 Claude로 더 깊게 종합합니다. 원문이 아니라 로컬에서 요약한 '증류층'만 전송하고, 봉인된 포착은 제외됩니다. 끄면 모두 로컬로 동작.")
                }

                if !transmissions.isEmpty {
                    Section("전송 기록") {
                        ForEach(transmissions.prefix(20)) { t in
                            HStack {
                                Text(t.date, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text("\(t.kind) · \(t.charCount)자").foregroundStyle(.secondary)
                            }.font(.caption)
                        }
                    }
                }

                Section {
                    Toggle("저녁 회고 알림", isOn: Binding(get: { reminders.enabled }, set: { reminders.setEnabled($0) }))
                    if reminders.enabled {
                        DatePicker("시각", selection: Binding(get: { reminders.timeAsDate }, set: { reminders.setTime($0) }),
                                   displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("리마인더")
                } footer: {
                    Text("매일 정한 시각에 '오늘을 한 줄로' 알림을 보내요. 탭하면 포착 화면으로 열립니다. 알림은 기기 안에서만 동작해요.")
                }

                Section {
                    Button { pass = ""; askingExportPass = true } label: {
                        Label("암호화 백업 내보내기", systemImage: "lock.doc")
                    }
                    Button { pass = ""; importingBackup = true } label: {
                        Label("백업에서 복원", systemImage: "arrow.down.doc")
                    }
                    if let m = backupMessage {
                        Text(m).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("백업")
                } footer: {
                    Text("모든 기록을 암호로 잠근 파일 하나로 내보내요(봉인 포함). 복원은 같은 암호로, 기존과 겹치지 않는 것만 더해집니다. 암호를 잊으면 복구할 수 없어요.")
                }

                Section {
                    NavigationLink {
                        TemplatesView()
                    } label: {
                        Label("정리 템플릿", systemImage: "text.alignleft")
                    }
                } header: {
                    Text("정리 스타일")
                } footer: {
                    Text("일·주·기간 정리 글의 톤·초점을 고르거나 직접 만들어요.")
                }

                Section("개발/측정") {
                    NavigationLink {
                        STTAccuracyView()
                    } label: {
                        Label("받아쓰기 정확도 측정", systemImage: "waveform.badge.magnifyingglass")
                    }
                }
            }
            .navigationTitle("설정")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { vault.setVault(url) }
            }
            // 백업 내보내기: 암호 입력 → 암호화 → 파일 저장
            .alert("백업 암호 설정", isPresented: $askingExportPass) {
                SecureField("암호 (잊으면 복구 불가)", text: $pass)
                Button("내보내기") { prepareExport() }.disabled(pass.isEmpty)
                Button("취소", role: .cancel) { pass = "" }
            } message: { Text("이 암호로 백업을 잠급니다.") }
            .fileExporter(isPresented: $showExport, document: exportDoc ?? BackupDocument(data: Data()),
                          contentType: .json, defaultFilename: "LivingRecord-backup") { result in
                if case .success = result { backupMessage = "백업을 내보냈어요." }
                exportDoc = nil
            }
            // 복원: 파일 선택 → 암호 입력 → 복호화·병합
            .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json, .data]) { result in
                if case .success(let url) = result { pendingImportURL = url; pass = ""; askingImportPass = true }
            }
            .alert("백업 암호 입력", isPresented: $askingImportPass) {
                SecureField("암호", text: $pass)
                Button("복원") { performImport() }.disabled(pass.isEmpty)
                Button("취소", role: .cancel) { pass = ""; pendingImportURL = nil }
            }
        }
    }

    private func prepareExport() {
        do {
            let file = try BackupService.gather(context: context)
            let data = try BackupService.encrypt(file, passphrase: pass)
            exportDoc = BackupDocument(data: data)
            showExport = true
        } catch { backupMessage = "백업 생성 실패." }
        pass = ""
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let file = try BackupService.decrypt(data, passphrase: pass)
            let r = BackupService.restore(file, into: context)
            backupMessage = "복원 완료 — \(r.added)개 추가, \(r.skipped)개 건너뜀."
        } catch BackupError.wrongPassphraseOrCorrupt {
            backupMessage = "암호가 틀리거나 손상된 파일이에요."
        } catch { backupMessage = "복원 실패." }
        pass = ""; pendingImportURL = nil
    }
}
