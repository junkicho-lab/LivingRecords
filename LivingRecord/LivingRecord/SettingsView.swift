import SwiftUI
import UniformTypeIdentifiers

// S3 — Obsidian 볼트 폴더 선택.
struct SettingsView: View {
    @Environment(VaultStore.self) private var vault
    @Environment(\.dismiss) private var dismiss
    @State private var picking = false

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
            }
            .navigationTitle("설정")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result { vault.setVault(url) }
            }
        }
    }
}
