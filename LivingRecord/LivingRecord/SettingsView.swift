import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// S3/S6b — Obsidian 볼트 + 클라우드 깊은 종합 설정.
struct SettingsView: View {
    @Environment(VaultStore.self) private var vault
    @Environment(CloudConsent.self) private var cloud
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Transmission.date, order: .reverse) private var transmissions: [Transmission]
    @State private var picking = false
    @State private var keyDraft = ""

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
                } header: {
                    Text("Obsidian 볼트")
                } footer: {
                    Text("포착이 이 폴더의 Captures 하위에 마크다운으로 미러됩니다. 봉인된 포착은 미러되지 않아요.")
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
            }
            .navigationTitle("설정")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { vault.setVault(url) }
            }
        }
    }
}
