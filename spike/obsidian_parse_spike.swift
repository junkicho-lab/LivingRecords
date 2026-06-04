// 스파이크 — 양방향 .md 파서 검증(앱 ObsidianMirrorImpl.parse와 동일 로직).
import Foundation

struct ParsedNote { let id: UUID?; let text: String; let theme: String? }
func parse(_ content: String) -> ParsedNote {
    var lines = content.components(separatedBy: "\n")
    var id: UUID?
    if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
        var i = 1
        while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) != "---" {
            let kv = lines[i].split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if kv.count == 2, kv[0] == "id" { id = UUID(uuidString: kv[1]) }
            i += 1
        }
        if i < lines.count { lines.removeSubrange(0...i) }
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

let uid = UUID()
// 1) 앱이 쓴 그대로
let appWritten = """
---
id: \(uid.uuidString)
created: 2026-06-04T09:00:00Z
source: voice
energy: 0.42
---

오늘 수업에서 발표 방식을 바꿨더니 좋았다

주제: [[수업]]
"""
let a = parse(appWritten)
print(a.id == uid && a.text == "오늘 수업에서 발표 방식을 바꿨더니 좋았다" && a.theme == "수업"
      ? "✅ 1 앱 작성본: id/본문/주제 정확" : "❌ 1 실패: \(a.id == uid) '\(a.text)' '\(a.theme ?? "nil")'")

// 2) Obsidian에서 본문 수정 + 주제 링크 변경
let edited = """
---
id: \(uid.uuidString)
created: 2026-06-04T09:00:00Z
source: voice
---

발표 방식을 바꾼 걸 다음 학기에도 이어가야겠다

주제: [[수업 개선]]
"""
let b = parse(edited)
print(b.id == uid && b.text.contains("이어가야겠다") && b.theme == "수업 개선"
      ? "✅ 2 편집본: 변경 본문/주제 반영" : "❌ 2 실패: '\(b.text)' '\(b.theme ?? "nil")'")

// 3) 손으로 쓴 새 파일(frontmatter 없음)
let handwritten = "갑자기 떠오른 생각: 주말에 글쓰기 모임을 만들어볼까"
let c = parse(handwritten)
print(c.id == nil && c.text == handwritten && c.theme == nil
      ? "✅ 3 손작성: id 없음, 본문 전체" : "❌ 3 실패: \(c.id == nil) '\(c.text)'")

// 4) frontmatter 있고 주제 없음(여러 줄 본문)
let multiline = """
---
id: \(uid.uuidString)
created: 2026-06-04T09:00:00Z
source: text
---

첫 줄
둘째 줄
"""
let d = parse(multiline)
print(d.text == "첫 줄\n둘째 줄" && d.theme == nil ? "✅ 4 여러 줄 본문 보존" : "❌ 4 실패: '\(d.text)'")
