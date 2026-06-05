import Foundation

// S3 — 포착을 Obsidian 볼트에 마크다운으로 단방향 미러. 봉인은 제외. (spike/obsidian_spike.swift 검증)
struct ObsidianMirrorImpl: ObsidianMirror {
    let store: VaultStore

    func mirror(_ capture: Capture) throws {
        // 봉인 포착은 별도 폴더('봉인')로 분리. (클라우드 깊은 종합엔 여전히 제외 — Distillation에서)
        let subdir = capture.sealed ? "봉인" : "Captures"
        store.write(subdir: subdir,
                    filename: Self.filename(capture),
                    content: Self.markdown(capture))
    }

    /// 주제 이름변경·이동·합치기 등으로 주제 링크가 바뀌었을 때 다시 쓴다.
    func remirror(_ captures: [Capture]) {
        for c in captures { try? mirror(c) }
    }

    /// 기록 삭제 시 미러된 .md도 제거.
    func delete(_ capture: Capture) {
        let subdir = capture.sealed ? "봉인" : "Captures"
        store.deleteFile(subdir: subdir, filename: Self.filename(capture))
    }

    func mirror(_ digest: Digest) throws {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        let kind: String
        switch digest.kind { case .daily: kind = "일일"; case .weekly: kind = "주간"; case .period: kind = "기간" }
        let fm = "---\ntype: digest\nkind: \(digest.kindRaw)\ndate: \(ISO8601DateFormatter().string(from: digest.periodStart))\n---\n\n"
        store.write(subdir: "Digests",
                    filename: "\(kind)정리 \(df.string(from: digest.periodStart)).md",
                    content: fm + digest.narrative + "\n")
    }

    static func filename(_ c: Capture) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HHmmss"
        return "\(f.string(from: c.createdAt)) \(c.id.uuidString.prefix(4)).md"
    }

    static func markdown(_ c: Capture) -> String {
        let iso = ISO8601DateFormatter().string(from: c.createdAt)
        let source = c.energy == nil ? "text" : "voice"
        // LLM wiki: 기계 필드(id/type/theme) + 그래프 링크. id는 위키 안정 앵커(청크 주소). 미러는 단방향(앱→볼트).
        var fm = "---\nid: \(c.id.uuidString)\ntype: capture\ncreated: \(iso)\nsource: \(source)\n"
        if let e = c.energy { fm += String(format: "energy: %.2f\n", e) }
        if let name = c.theme?.name, !name.isEmpty { fm += "theme: \"\(WikiBuilder.yamlEscape(name))\"\n" }
        fm += "---\n\n\(c.text)\n"
        if let name = c.theme?.name, !name.isEmpty {     // 주제 허브로 연결되는 위키링크
            fm += "\n주제: [[\(WikiBuilder.safeName(name))]]\n"
        }
        return fm
    }
}
