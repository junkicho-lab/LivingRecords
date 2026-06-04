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
        capture.mirrored = true   // 양방향 동기화 삭제 안전장치(미러된 것만 삭제 대상)
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
        var fm = "---\nid: \(c.id.uuidString)\ncreated: \(iso)\nsource: \(source)\n"   // id = 양방향 매핑 키
        if let e = c.energy { fm += String(format: "energy: %.2f\n", e) }
        fm += "---\n\n\(c.text)\n"
        if let name = c.theme?.name, !name.isEmpty {     // Obsidian 그래프용 주제 위키링크
            fm += "\n주제: [[\(name)]]\n"
        }
        return fm
    }

    // 양방향 — 미러된 .md를 다시 읽어 (id, 본문, 주제) 추출. 사용자가 Obsidian에서 편집한 결과 반영용.
    struct ParsedNote { let id: UUID?; let text: String; let theme: String? }
    static func parse(_ content: String) -> ParsedNote {
        var lines = content.components(separatedBy: "\n")
        var id: UUID?
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            var i = 1
            while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) != "---" {
                let kv = lines[i].split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if kv.count == 2, kv[0] == "id" { id = UUID(uuidString: kv[1]) }
                i += 1
            }
            if i < lines.count { lines.removeSubrange(0...i) }   // frontmatter 제거(닫는 --- 포함)
        }
        var theme: String?
        lines.removeAll { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("주제:"), let lo = t.range(of: "[["), let hi = t.range(of: "]]") else { return false }
            theme = String(t[lo.upperBound..<hi.lowerBound]).trimmingCharacters(in: .whitespaces)
            return true
        }
        let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedNote(id: id, text: text, theme: theme)
    }
}
