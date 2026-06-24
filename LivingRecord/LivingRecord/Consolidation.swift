import Foundation
import SwiftData

// S4 — 주제 통합. FM 의미 배정(spike ⑥)으로 가장 맞는 주제에 붙이거나 새 주제 생성.
// 임베딩 임계값은 폐기(유사도 순서 어긋남). 임베딩은 저장만(향후 top-K 후보용).
enum Consolidator {
    // 통합 직렬화: 동시 실행 시 주제 목록이 stale 해져 오배정 → 한 번에 하나씩 순차 처리.
    @MainActor private static var tail: Task<Void, Never>?

    @MainActor
    static func enqueue(_ capture: Capture, context: ModelContext, vault: VaultStore, consent: CloudConsent) {
        let prev = tail
        tail = Task { @MainActor in
            _ = await prev?.value
            await consolidate(capture, context: context, vault: vault, consent: consent)
        }
    }

    @MainActor
    static func consolidate(_ capture: Capture, context: ModelContext, vault: VaultStore, consent: CloudConsent) async {
        // 임베딩 저장 — 배정 후보를 top-K로 좁히는 데도 쓴다(아래 candidates 순위).
        capture.embedding = EmbedderImpl.shared.embed(capture.text)
        try? context.save()

        // 후보 스냅샷 구성(MainActor): 주제별 임베딩 중심 + 대표 스니펫(봉인 원문은 로컬 FM에도 안 넣음).
        let themes = (try? context.fetch(FetchDescriptor<Theme>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let center = EmbedderImpl.shared.centeringVector()
        let candidates: [ThemeCandidate] = themes.enumerated().map { (i, t) in
            let members = t.captures
            let centroid = VectorMath.mean(members.compactMap { $0.embedding })   // 봉인 포함(벡터만, 텍스트 아님)
            let snippets = members.filter { !$0.sealed }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(3).map { snippet($0.text) }
            let confirmed = members.filter { $0.userConfirmed }.compactMap { $0.embedding }   // 학습 신호
            return ThemeCandidate(index: i, name: t.name, centroid: centroid,
                                  snippets: snippets, confirmedEmbeddings: confirmed)
        }
        // 배정: 봉인이 아니고 '클라우드 분류'를 옵트인했으면 원문을 Claude로 보내 분류(고품질).
        // 실패하면 로컬로 폴백. 봉인 포착은 절대 클라우드로 보내지 않는다(항상 로컬).
        var idx = -2
        if !capture.sealed, !candidates.isEmpty, consent.canClassifyInCloud, let key = consent.apiKey {
            let cloudCands = candidates.map { CloudThemeClassifier.Candidate(name: $0.name, snippets: $0.snippets) }
            if let cloudIdx = await CloudThemeClassifier.classify(memo: capture.text, candidates: cloudCands, apiKey: key) {
                context.insert(Transmission(kind: "classify", charCount: capture.text.count))   // 전송 로그(투명성)
                idx = cloudIdx
            }
        }
        if idx == -2 {   // 클라우드 미사용·실패 → 로컬 배정
            idx = await ThemeAssigner.assign(capture.text, memoEmbedding: capture.embedding,
                                             candidates: candidates, center: center)
        }

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
        if let th = capture.theme {                            // LLM wiki: 주제 허브·index 갱신
            WikiBuilder.updateTheme(th, context: context, vault: vault)
            WikiBuilder.updateIndex(context: context, vault: vault)
        }

        // S8 — 의도 감지(결정적 어미 게이트). 있으면 약속(Commitment) 생성. 봉인 포함(다짐도 사적일 수 있음; 클라우드엔 안 감).
        let detector = IntentionDetectorImpl()
        if detector.hasIntention(capture.text) {
            let phrase = await detector.extractPhrase(capture.text)
            let com = Commitment(text: phrase, themeID: capture.theme?.id,
                                 themeName: capture.theme?.name ?? "", createdAt: capture.createdAt)
            context.insert(com)
            try? context.save()
        }
    }

    static func placeholderName(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
    }

    // 후보 판단용 짧은 스니펫(한 줄, 60자).
    private static func snippet(_ t: String) -> String {
        let s = t.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        return s.count > 60 ? String(s.prefix(60)) + "…" : s
    }
}
