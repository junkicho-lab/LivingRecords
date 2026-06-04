// 스파이크 — Obsidian 마크다운 미러 로직 (frontmatter + 본문, 봉인 제외)
// 실행: swift obsidian_spike.swift
import Foundation

struct Cap { let text: String; let created: Date; let energy: Double?; let source: String; let sealed: Bool }

func stamp(_ d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HHmmss"; return f.string(from: d)
}
func iso(_ d: Date) -> String {
    let f = ISO8601DateFormatter(); return f.string(from: d)
}

// 봉인이면 nil(미러 제외). 아니면 (파일명, 내용).
func mirrorFile(_ c: Cap) -> (name: String, content: String)? {
    guard !c.sealed else { return nil }
    var fm = "---\ncreated: \(iso(c.created))\nsource: \(c.source)\n"
    if let e = c.energy { fm += String(format: "energy: %.2f\n", e) }
    fm += "---\n\n\(c.text)\n"
    return ("\(stamp(c.created)).md", fm)
}

// 임시 볼트에 써보고 검증
let vault = FileManager.default.temporaryDirectory.appendingPathComponent("vault-test/Captures")
try? FileManager.default.removeItem(at: vault)
try! FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)

let now = Date(timeIntervalSince1970: 1_780_000_000)
let caps = [
    Cap(text: "수업 회고를 글로 남기기 시작했다.", created: now, energy: 0.67, source: "voice", sealed: false),
    Cap(text: "이건 아주 사적인 생각.", created: now.addingTimeInterval(60), energy: 0.4, source: "text", sealed: true),
]
var written = 0
for c in caps {
    if let f = mirrorFile(c) {
        try! f.content.write(to: vault.appendingPathComponent(f.name), atomically: true, encoding: .utf8)
        written += 1
    }
}
let files = (try? FileManager.default.contentsOfDirectory(atPath: vault.path)) ?? []
print("작성된 파일 수: \(written) (봉인 1건 제외 → 1 기대)")
print("폴더 내용: \(files)")
print("\n--- 미러된 .md 내용 ---")
if let first = files.first { print(try! String(contentsOf: vault.appendingPathComponent(first), encoding: .utf8)) }
print("판정: \(written == 1 && files.count == 1 ? "✅ 봉인 제외 + frontmatter 정상" : "⚠️ 확인 필요")")
