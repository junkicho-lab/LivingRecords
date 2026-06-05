import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// 설정 — 그룹별 카테고리 → 각 상세 화면(직관적 정리).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("저장 & 동기화") {
                    NavigationLink { ObsidianSettingsView() } label: { Label("Obsidian 볼트", systemImage: "folder") }
                    NavigationLink { BackupSettingsView() } label: { Label("백업 & 복원", systemImage: "lock.doc") }
                }
                Section("정리 & 가공") {
                    NavigationLink { TemplatesView() } label: { Label("정리 템플릿", systemImage: "text.alignleft") }
                    NavigationLink { CloudSettingsView() } label: { Label("클라우드 깊은 종합", systemImage: "cloud") }
                }
                Section("알림") {
                    NavigationLink { ReminderSettingsView() } label: { Label("저녁 회고 알림", systemImage: "bell") }
                }
                Section("도구") {
                    NavigationLink { STTAccuracyView() } label: { Label("받아쓰기 정확도 측정", systemImage: "waveform.badge.magnifyingglass") }
                }
            }
            .navigationTitle("설정")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }
    }
}

// MARK: - Obsidian 볼트 (저장·단방향 미러·양방향 가져오기)
struct ObsidianSettingsView: View {
    @Environment(VaultStore.self) private var vault
    @State private var picking = false

    var body: some View {
        Form {
            Section {
                if let u = vault.vaultURL {
                    Label(u.lastPathComponent, systemImage: "folder.fill").foregroundStyle(.secondary)
                } else {
                    Text("아직 선택 안 됨").foregroundStyle(.secondary)
                }
                Button(vault.vaultURL == nil ? "볼트 폴더 선택" : "볼트 폴더 변경") { picking = true }
            } footer: {
                Text("포착·정리가 이 폴더에 마크다운으로 단방향 미러됩니다(Captures/·봉인/·Digests/). 봉인은 '봉인' 폴더로 따로 저장돼요(클라우드 종합엔 제외). 볼트가 iCloud 동기화되면 봉인도 기기를 떠나니 유의하세요.")
            }
        }
        .navigationTitle("Obsidian 볼트")
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { vault.setVault(url) }
        }
    }
}

// MARK: - 클라우드 깊은 종합
struct CloudSettingsView: View {
    @Environment(CloudConsent.self) private var cloud
    @Query(sort: \Transmission.date, order: .reverse) private var transmissions: [Transmission]
    @State private var keyDraft = ""

    var body: some View {
        Form {
            Section {
                Toggle("깊은 종합에 클라우드 사용", isOn: Binding(get: { cloud.enabled }, set: { cloud.enabled = $0 }))
                SecureField("Claude API 키", text: $keyDraft)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                HStack {
                    Button("키 저장") { cloud.setAPIKey(keyDraft); keyDraft = "" }
                        .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    Spacer()
                    if cloud.hasAPIKey {
                        Label("저장됨", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                        Button("삭제", role: .destructive) { cloud.setAPIKey("") }.font(.caption)
                    }
                }
            } footer: {
                Text("켜면 주간·기간 정리를 Claude로 더 깊게 종합합니다. 원문이 아니라 로컬에서 요약한 '증류층'만 전송하고, 봉인된 포착은 제외됩니다. 끄면 모두 로컬로 동작.")
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
        }
        .navigationTitle("클라우드 깊은 종합")
    }
}

// MARK: - 저녁 회고 리마인더
struct ReminderSettingsView: View {
    @Environment(ReminderStore.self) private var reminders
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section {
                Toggle("저녁 회고 알림", isOn: Binding(get: { reminders.enabled }, set: { reminders.setEnabled($0, context: context) }))
                if reminders.enabled {
                    DatePicker("시각", selection: Binding(get: { reminders.timeAsDate }, set: { reminders.setTime($0, context: context) }),
                               displayedComponents: .hourAndMinute)
                }
            } footer: {
                Text("매일 정한 시각에 그날의 '되새김'(과거가 안부)을 알림으로 보내요. 탭하면 흐름 탭에서 그 기록을 봐요. 되새길 게 없으면 '오늘을 한 줄로' 포착 권유로. 알림은 기기 안에서만 동작해요.")
            }
        }
        .navigationTitle("저녁 회고 알림")
    }
}

// MARK: - 백업 & 복원 (암호화)
struct BackupSettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var pass = ""
    @State private var askingExportPass = false
    @State private var askingImportPass = false
    @State private var showExport = false
    @State private var importingBackup = false
    @State private var exportDoc: BackupDocument?
    @State private var pendingImportURL: URL?
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                Button { pass = ""; askingExportPass = true } label: { Label("암호화 백업 내보내기", systemImage: "lock.doc") }
                Button { pass = ""; importingBackup = true } label: { Label("백업에서 복원", systemImage: "arrow.down.doc") }
                if let m = message { Text(m).font(.caption).foregroundStyle(.secondary) }
            } footer: {
                Text("모든 기록을 암호로 잠근 파일 하나로 내보내요(봉인 포함). 복원은 같은 암호로, 기존과 겹치지 않는 것만 더해집니다. 암호를 잊으면 복구할 수 없어요.")
            }
        }
        .navigationTitle("백업 & 복원")
        .alert("백업 암호 설정", isPresented: $askingExportPass) {
            SecureField("암호 (잊으면 복구 불가)", text: $pass)
            Button("내보내기") { prepareExport() }.disabled(pass.isEmpty)
            Button("취소", role: .cancel) { pass = "" }
        } message: { Text("이 암호로 백업을 잠급니다.") }
        .fileExporter(isPresented: $showExport, document: exportDoc ?? BackupDocument(data: Data()),
                      contentType: .json, defaultFilename: "LivingRecord-backup") { result in
            if case .success = result { message = "백업을 내보냈어요." }
            exportDoc = nil
        }
        .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json, .data]) { result in
            if case .success(let url) = result { pendingImportURL = url; pass = ""; askingImportPass = true }
        }
        .alert("백업 암호 입력", isPresented: $askingImportPass) {
            SecureField("암호", text: $pass)
            Button("복원") { performImport() }.disabled(pass.isEmpty)
            Button("취소", role: .cancel) { pass = ""; pendingImportURL = nil }
        }
    }

    private func prepareExport() {
        do {
            let file = try BackupService.gather(context: context)
            exportDoc = BackupDocument(data: try BackupService.encrypt(file, passphrase: pass))
            showExport = true
        } catch { message = "백업 생성 실패." }
        pass = ""
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let file = try BackupService.decrypt(try Data(contentsOf: url), passphrase: pass)
            let r = BackupService.restore(file, into: context)
            message = "복원 완료 — \(r.added)개 추가, \(r.skipped)개 건너뜀."
        } catch BackupError.wrongPassphraseOrCorrupt {
            message = "암호가 틀리거나 손상된 파일이에요."
        } catch { message = "복원 실패." }
        pass = ""; pendingImportURL = nil
    }
}
