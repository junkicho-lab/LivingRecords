import Foundation
import SwiftData

// post-v4 — 양방향 Obsidian. Obsidian에서 .md를 편집/추가/삭제한 결과를 앱으로 가져온다(가져오기 시 Obsidian 우선).
// 안전장치: ①볼트 폴더 없으면 삭제 안 함 ②미러된 적 있는 포착만 삭제(늦게 연결한 기존 포착 보호)
// ③막 만든 포착(60초)은 비동기 미러 레이스로 보호.
enum SyncOutcome {
    case ok(updated: Int, imported: Int, deleted: Int)
    case noVault
    case noFolders     // Captures/봉인 폴더가 없음 → 잘못된/빈 볼트일 수 있어 아무것도 지우지 않음

    var message: String {
        switch self {
        case .noVault: return "Obsidian 볼트가 연결돼 있지 않아요."
        case .noFolders: return "볼트에 Captures/봉인 폴더가 없어요. (포착을 먼저 미러하세요)"
        case let .ok(u, i, d): return "동기화 완료 — 반영 \(u) · 가져옴 \(i) · 삭제 \(d)"
        }
    }
}

enum ObsidianSync {
    static let graceSeconds: TimeInterval = 60

    @MainActor
    static func pull(context: ModelContext, vault: VaultStore, now: Date = Date()) -> SyncOutcome {
        guard vault.vaultURL != nil else { return .noVault }
        let hasCaptures = vault.subdirExists("Captures"), hasSealed = vault.subdirExists("봉인")
        guard hasCaptures || hasSealed else { return .noFolders }   // 안전장치 ①

        // 볼트 노트 수집
        var byID: [UUID: (text: String, theme: String?, sealed: Bool)] = [:]
        var noID: [(text: String, theme: String?, sealed: Bool)] = []
        func collect(_ subdir: String, sealed: Bool) {
            for f in vault.listMarkdown(subdir: subdir) {
                let p = ObsidianMirrorImpl.parse(f.content)
                guard !p.text.isEmpty else { continue }
                if let id = p.id { byID[id] = (p.text, p.theme, sealed) }
                else { noID.append((p.text, p.theme, sealed)) }
            }
        }
        if hasCaptures { collect("Captures", sealed: false) }
        if hasSealed { collect("봉인", sealed: true) }

        let mirror = ObsidianMirrorImpl(store: vault)
        let caps = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        var themeByName = Dictionary(themes.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        func theme(named name: String?) -> Theme? {
            guard let n = name, !n.isEmpty else { return nil }
            if let t = themeByName[n] { return t }
            let t = Theme(name: n); context.insert(t); themeByName[n] = t; return t
        }

        var updated = 0, imported = 0, deleted = 0
        let capIDs = Set(caps.map { $0.id })

        // 1) 기존 매칭 → 본문/주제/봉인 반영(Obsidian 우선), 파일 재미러로 정규화
        for c in caps {
            guard let n = byID[c.id] else { continue }
            var changed = false
            if c.text != n.text { c.text = n.text; changed = true }
            if (n.theme ?? "") != (c.theme?.name ?? "") { c.theme = theme(named: n.theme); changed = true }
            if c.sealed != n.sealed { c.sealed = n.sealed; changed = true }
            if changed { updated += 1; try? mirror.mirror(c) }
        }

        // 2) 새 파일(미지의 id 또는 id 없음) → 새 포착
        for (id, n) in byID where !capIDs.contains(id) {
            let cap = Capture(text: n.text, sealed: n.sealed); cap.id = id
            cap.theme = theme(named: n.theme)
            context.insert(cap); imported += 1; try? mirror.mirror(cap)
        }
        for n in noID {
            let cap = Capture(text: n.text, sealed: n.sealed)
            cap.theme = theme(named: n.theme)
            context.insert(cap); imported += 1; try? mirror.mirror(cap)
        }

        // 3) 삭제: 미러된 적 있는데 볼트에서 사라진 포착 (안전장치 ②③)
        for c in caps where c.mirrored && byID[c.id] == nil {
            guard now.timeIntervalSince(c.createdAt) >= graceSeconds else { continue }
            let th = c.theme
            mirror.delete(c); context.delete(c); deleted += 1
            if let th, th.captures.isEmpty { context.delete(th) }
        }

        try? context.save()
        return .ok(updated: updated, imported: imported, deleted: deleted)
    }

    // 전체 다시 내보내기 — 기존 파일에 id/frontmatter 갱신 + mirrored 표시(가져오기 삭제가 안전해짐).
    @MainActor
    static func reexportAll(context: ModelContext, vault: VaultStore) -> Int {
        guard vault.vaultURL != nil else { return 0 }
        let mirror = ObsidianMirrorImpl(store: vault)
        let caps = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        for c in caps { try? mirror.mirror(c) }
        try? context.save()
        return caps.count
    }
}
