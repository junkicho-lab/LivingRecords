import Foundation
import SwiftData

// S4c — 기록 재배치(이동/추출) 공용 로직. 비워진 원본 주제는 자동 삭제.
enum Curation {
    @MainActor
    static func move(_ captures: [Capture], to target: Theme, context: ModelContext, vault: VaultStore) {
        let sourceNames = Set(captures.compactMap { $0.theme?.name })
        let sourceThemes = captures.compactMap { $0.theme }
        for c in captures { c.theme = target }
        cleanup(sourceThemes, except: target, ids: Set(sourceThemes.map { ObjectIdentifier($0) }), context: context)
        try? context.save()
        ObsidianMirrorImpl(store: vault).remirror(captures)   // 주제 링크 갱신
        refreshHubs(sourceNames: sourceNames, target: target, context: context, vault: vault)
    }

    @MainActor
    static func extractToNew(_ captures: [Capture], context: ModelContext, vault: VaultStore) {
        guard let first = captures.first else { return }
        let sourceNames = Set(captures.compactMap { $0.theme?.name })
        let sourceThemes = captures.compactMap { $0.theme }
        let t = Theme(name: Consolidator.placeholderName(first.text))
        context.insert(t)
        for c in captures { c.theme = t }
        cleanup(sourceThemes, except: t, ids: Set(sourceThemes.map { ObjectIdentifier($0) }), context: context)
        try? context.save()
        ObsidianMirrorImpl(store: vault).remirror(captures)   // 주제 링크 갱신
        refreshHubs(sourceNames: sourceNames, target: t, context: context, vault: vault)
    }

    // 이동/추출 후 위키 허브 갱신: 남은 원본은 갱신, 비워져 사라진 원본은 허브 삭제. + 대상 + index.
    @MainActor
    static func refreshHubs(sourceNames: Set<String>, target: Theme, context: ModelContext, vault: VaultStore) {
        guard vault.vaultURL != nil else { return }
        let remaining = Dictionary(((try? context.fetch(FetchDescriptor<Theme>())) ?? []).map { ($0.name, $0) },
                                   uniquingKeysWith: { a, _ in a })
        for name in sourceNames where name != target.name {
            if let t = remaining[name] { WikiBuilder.updateTheme(t, context: context, vault: vault) }
            else { WikiBuilder.deleteTheme(named: name, vault: vault) }
        }
        WikiBuilder.updateTheme(target, context: context, vault: vault)
        WikiBuilder.updateIndex(context: context, vault: vault)
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
