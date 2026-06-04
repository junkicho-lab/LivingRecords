import SwiftUI
import SwiftData

// post-v4 — 정리 템플릿 관리/선택. 프리셋 + 내 템플릿. 활성 하나가 모든 정리(일/주/기간) 스타일에 적용.
struct TemplatesView: View {
    @Environment(\.modelContext) private var context
    @Environment(TemplateStore.self) private var store
    @Query(sort: \CustomTemplate.createdAt) private var customs: [CustomTemplate]
    @State private var editing: CustomTemplate?
    @State private var showNew = false
    @State private var draftName = ""
    @State private var draftDirective = ""

    var body: some View {
        List {
            Section {
                ForEach(Templates.builtins) { t in
                    row(key: "builtin:\(t.key)", name: t.name, directive: t.directive)
                }
            } header: { Text("프리셋") }

            Section {
                if customs.isEmpty {
                    Text("내가 만든 템플릿이 여기 쌓여요.").foregroundStyle(.secondary).font(.caption)
                }
                ForEach(customs) { t in
                    row(key: "custom:\(t.id.uuidString)", name: t.name, directive: t.directive)
                        .contextMenu {
                            Button { startEdit(t) } label: { Label("편집", systemImage: "pencil") }
                            Button(role: .destructive) { delete(t) } label: { Label("삭제", systemImage: "trash") }
                        }
                }
                Button { startNew() } label: { Label("새 템플릿", systemImage: "plus.circle") }
            } header: { Text("내 템플릿") } footer: {
                Text("템플릿은 정리 글의 '스타일·초점'을 정해요. 지속 후보·다짐 같은 구조는 그대로예요.")
            }
        }
        .navigationTitle("정리 템플릿")
        .sheet(isPresented: $showNew) { editor(title: editing == nil ? "새 템플릿" : "템플릿 편집") }
    }

    private func row(key: String, name: String, directive: String) -> some View {
        Button {
            store.activeKey = key
        } label: {
            HStack(alignment: .top) {
                Image(systemName: store.activeKey == key ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(store.activeKey == key ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).foregroundStyle(.primary)
                    Text(directive).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private func editor(title: String) -> some View {
        NavigationStack {
            Form {
                TextField("이름 (예: 코칭 톤)", text: $draftName)
                Section("스타일 지시") {
                    TextField("예: 다정하게, 칭찬 한 줄과 다음 한 걸음을 제안해줘", text: $draftDirective, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty
                                                       || draftDirective.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func startNew() { editing = nil; draftName = ""; draftDirective = ""; showNew = true }
    private func startEdit(_ t: CustomTemplate) { editing = t; draftName = t.name; draftDirective = t.directive; showNew = true }

    private func save() {
        let n = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = draftDirective.trimmingCharacters(in: .whitespacesAndNewlines)
        if let t = editing { t.name = n; t.directive = d }
        else {
            let t = CustomTemplate(name: n, directive: d)
            context.insert(t)
            store.activeKey = "custom:\(t.id.uuidString)"   // 새로 만든 건 바로 활성
        }
        try? context.save()
        showNew = false
    }

    private func delete(_ t: CustomTemplate) {
        if store.activeKey == "custom:\(t.id.uuidString)" { store.activeKey = Templates.activeKeyDefault }
        context.delete(t); try? context.save()
    }
}
