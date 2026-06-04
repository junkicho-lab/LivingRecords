import Foundation
import SwiftData

// S4c — 기록 재배치(이동/추출) 공용 로직. 비워진 원본 주제는 자동 삭제.
enum Curation {
    @MainActor
    static func move(_ captures: [Capture], to target: Theme, context: ModelContext, vault: VaultStore) {
        let sourceThemes = captures.compactMap { $0.theme }
        for c in captures { c.theme = target }
        cleanup(sourceThemes, except: target, ids: Set(sourceThemes.map { ObjectIdentifier($0) }), context: context)
        try? context.save()
        ObsidianMirrorImpl(store: vault).remirror(captures)   // 주제 링크 갱신
    }

    @MainActor
    static func extractToNew(_ captures: [Capture], context: ModelContext, vault: VaultStore) {
        guard let first = captures.first else { return }
        let sourceThemes = captures.compactMap { $0.theme }
        let t = Theme(name: Consolidator.placeholderName(first.text))
        context.insert(t)
        for c in captures { c.theme = t }
        cleanup(sourceThemes, except: t, ids: Set(sourceThemes.map { ObjectIdentifier($0) }), context: context)
        try? context.save()
        ObsidianMirrorImpl(store: vault).remirror(captures)   // 주제 링크 갱신
    }

    @MainActor
    private static func cleanup(_ themes: [Theme], except keep: Theme, ids: Set<ObjectIdentifier>, context: ModelContext) {
        var seen = Set<ObjectIdentifier>()
        for t in themes where t !== keep {
            let oid = ObjectIdentifier(t)
            if seen.contains(oid) { continue }
            seen.insert(oid)
            if t.captures.isEmpty { context.delete(t) }
        }
    }
}
