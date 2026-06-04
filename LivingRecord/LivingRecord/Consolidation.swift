import Foundation
import SwiftData

// S4 — 주제 통합. FM 의미 배정(spike ⑥)으로 가장 맞는 주제에 붙이거나 새 주제 생성.
// 임베딩 임계값은 폐기(유사도 순서 어긋남). 임베딩은 저장만(향후 top-K 후보용).
enum Consolidator {
    // 통합 직렬화: 동시 실행 시 주제 목록이 stale 해져 오배정 → 한 번에 하나씩 순차 처리.
    @MainActor private static var tail: Task<Void, Never>?

    @MainActor
    static func enqueue(_ capture: Capture, context: ModelContext, vault: VaultStore) {
        let prev = tail
        tail = Task { @MainActor in
            _ = await prev?.value
            await consolidate(capture, context: context, vault: vault)
        }
    }

    @MainActor
    static func consolidate(_ capture: Capture, context: ModelContext, vault: VaultStore) async {
        // 임베딩 저장(향후 활용). 배정 결정엔 사용 안 함.
        capture.embedding = EmbedderImpl.shared.embed(capture.text)
        try? context.save()

        let themes = (try? context.fetch(FetchDescriptor<Theme>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let idx = await ThemeAssigner.assign(capture.text, themeNames: themes.map { $0.name })

        if idx >= 0 && idx < themes.count {
            capture.theme = themes[idx]               // 기존 주제에 합류
            try? context.save()
        } else {
            let t = Theme(name: placeholderName(capture.text))   // 새 주제(임시 이름)
            context.insert(t)
            capture.theme = t
            try? context.save()
            let name = await ThemeNamer.name(for: capture.text)  // FM 이름짓기(+폴백)
            t.name = name
            try? context.save()
        }
        try? ObsidianMirrorImpl(store: vault).mirror(capture)   // 주제 확정 후 미러(주제 [[링크]] 포함, 봉인 제외)
    }

    static func placeholderName(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
    }
}
