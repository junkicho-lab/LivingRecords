import Foundation
import SwiftData

// LLM wiki (슬라이스 A — 구조) — 볼트를 '읽을 수 있는 지식 베이스'로. 단방향 쓰기만(중복 위험 0).
// 주제(Theme)당 허브 노트 + index(MOC). 봉인 제외. AI 종합('## 한눈에')은 슬라이스 B(클라우드 옵트인).
enum WikiBuilder {
    // 파일명·위키링크 안전화(경로/링크 깨는 문자 제거). 캡처 링크와 허브 파일명에 동일 적용.
    static func safeName(_ s: String) -> String {
        var out = s
        for ch in ["/", "\\", ":", "[", "]", "#", "^", "|", "*", "?", "\"", "<", ">"] {
            out = out.replacingOccurrences(of: ch, with: " ")
        }
        out = out.trimmingCharacters(in: .whitespaces)
        return out.isEmpty ? "주제" : out
    }
    static func yamlEscape(_ s: String) -> String { s.replacingOccurrences(of: "\"", with: "'") }

    private static func snippet(_ t: String) -> String {
        let s = t.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        return s.count > 40 ? String(s.prefix(40)) + "…" : s
    }
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    // 한 주제의 허브 노트 재생성(덮어쓰기 → 멱등). 봉인 제외. 비면 허브 삭제.
    @MainActor
    static func updateTheme(_ theme: Theme, context: ModelContext, vault: VaultStore, now: Date = Date()) {
        guard vault.vaultURL != nil else { return }
        let caps = theme.captures.filter { !$0.sealed }
        guard let first = caps.map({ $0.createdAt }).min(),
              let last = caps.map({ $0.createdAt }).max() else {
            deleteTheme(named: theme.name, vault: vault); return
        }
        let sorted = caps.sorted { $0.createdAt > $1.createdAt }
        let decisions = ((try? context.fetch(FetchDescriptor<Decision>())) ?? [])
            .filter { $0.theme?.persistentModelID == theme.persistentModelID }

        var md = "---\ntype: theme\n"
        md += "name: \"\(yamlEscape(theme.name))\"\n"
        md += "state: \(theme.state.rawValue)\n"
        md += "count: \(caps.count)\n"
        md += "first: \(dayFmt.string(from: first))\n"
        md += "last: \(dayFmt.string(from: last))\n"
        if let v = decisions.sorted(by: { $0.createdAt < $1.createdAt }).last?.verdict {
            md += "decision: \(PeriodReview.verdictLabel(v))\n"
        }
        md += "updated: \(ISO8601DateFormatter().string(from: now))\n---\n\n"
        md += "# \(theme.name)\n"
        if let s = theme.summary, !s.isEmpty {     // 클라우드 AI 종합(슬라이스 B)
            md += "\n## 한눈에\n\(s)\n"
        }
        if let p = Precedent.line(decisions: decisions, themeCaptures: theme.captures, now: now) {
            md += "\n## 결정\n- \(p)\n"
        }
        md += "\n## 기록 (\(caps.count))\n"
        for c in sorted.prefix(300) {
            let link = String(ObsidianMirrorImpl.filename(c).dropLast(3))   // ".md" 제거
            md += "- [[\(link)]] — \(snippet(c.text))\n"
        }
        vault.write(subdir: "Themes", filename: "\(safeName(theme.name)).md", content: md)
    }

    @MainActor
    static func deleteTheme(named name: String, vault: VaultStore) {
        vault.deleteFile(subdir: "Themes", filename: "\(safeName(name)).md")
    }

    // index(MOC) — 오래 이어진 줄기 + 모든 주제 허브 링크. LLM 에이전트의 출발점.
    @MainActor
    static func updateIndex(context: ModelContext, vault: VaultStore, now: Date = Date()) {
        guard vault.vaultURL != nil else { return }
        let themes = ((try? context.fetch(FetchDescriptor<Theme>())) ?? [])
            .filter { !$0.captures.filter { !$0.sealed }.isEmpty }
        let sorted = themes.sorted { $0.captures.count > $1.captures.count }
        let lines = Throughlines.compute(themes)

        var md = "---\ntype: index\nupdated: \(ISO8601DateFormatter().string(from: now))\n---\n\n"
        md += "# 생동하는 기록 — 색인\n"
        if !lines.isEmpty {
            md += "\n## 오래 이어진 줄기\n"
            for t in lines { md += "- [[\(safeName(t.theme.name))]] — \(t.distinctWeeks)주에 걸쳐 \(t.count)회\n" }
        }
        md += "\n## 모든 주제 (\(sorted.count))\n"
        for t in sorted {
            md += "- [[\(safeName(t.name))]] (\(t.captures.filter { !$0.sealed }.count))\n"
        }
        vault.write(subdir: "", filename: "index.md", content: md)
    }

    // 전체 재빌드 — 기존 데이터에 위키 구조를 입힘(포착 노트 재미러 + 모든 허브 + index).
    @MainActor
    static func rebuildAll(context: ModelContext, vault: VaultStore) -> Int {
        guard vault.vaultURL != nil else { return 0 }
        let mirror = ObsidianMirrorImpl(store: vault)
        let caps = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        for c in caps { try? mirror.mirror(c) }                 // 강화된 frontmatter로 재기록(봉인은 봉인/)
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        for t in themes { updateTheme(t, context: context, vault: vault) }
        updateIndex(context: context, vault: vault)
        return themes.count
    }
    // 관련 주제: 임베딩 유사도 순위가 거칠어(spike ⑥) 엉뚱하게 묶여 제거함. 허브는 결정·한눈에·기록으로 충분.
}
