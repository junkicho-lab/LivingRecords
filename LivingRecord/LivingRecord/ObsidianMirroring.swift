import Foundation

// S3 — 포착을 Obsidian 볼트에 마크다운으로 단방향 미러. 봉인은 제외. (spike/obsidian_spike.swift 검증)
struct ObsidianMirrorImpl: ObsidianMirror {
    let store: VaultStore

    func mirror(_ capture: Capture) throws {
        guard !capture.sealed else { return }            // 봉인 제외(기기 밖으로 안 나감)
        store.write(subdir: "Captures",
                    filename: Self.filename(capture),
                    content: Self.markdown(capture))
    }

    /// 주제 이름변경·이동·합치기 등으로 주제 링크가 바뀌었을 때 다시 쓴다(봉인 제외).
    func remirror(_ captures: [Capture]) {
        for c in captures where !c.sealed { try? mirror(c) }
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
        var fm = "---\ncreated: \(iso)\nsource: \(source)\n"
        if let e = c.energy { fm += String(format: "energy: %.2f\n", e) }
        fm += "---\n\n\(c.text)\n"
        if let name = c.theme?.name, !name.isEmpty {     // Obsidian 그래프용 주제 위키링크
            fm += "\n주제: [[\(name)]]\n"
        }
        return fm
    }
}
