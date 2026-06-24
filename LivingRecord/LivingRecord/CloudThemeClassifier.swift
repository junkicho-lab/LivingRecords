import Foundation

// 클라우드 주제 분류(옵트인) — 로컬 FM보다 높은 품질로 새 포착을 기존 주제에 배정.
// ⚠️ 이건 포착 '원문'을 클라우드(Claude)로 보낸다. '증류층(요약)'만 보내는 깊은 종합(CloudSynthesizer)과
//    다른 프라이버시 단계라 별도 동의(CloudConsent.classifyEnabled)를 쓴다. 봉인 포착은 호출부에서 차단.
enum CloudThemeClassifier {
    static let model = "claude-sonnet-4-6"

    static let system = """
    너는 짧은 메모를 사용자의 기존 '주제' 중 가장 알맞은 하나로 분류하는 도우미다.
    각 주제는 번호·이름과 대표 기록 몇 개로 주어진다.
    - 새 메모가 잘 맞는 기존 주제가 있으면 그 번호(0부터)를 고른다.
    - 어디에도 잘 안 맞으면 -1(새 주제). 억지로 끼워맞추지 말 것. 애매하면 -1.
    반드시 JSON 한 줄로만 답하라: {"match": <번호 또는 -1>}
    """

    struct Candidate { let name: String; let snippets: [String] }

    /// 반환: 0..<candidates.count = 기존 주제 / -1 = 새 주제 / nil = 호출 실패(→ 호출부가 로컬 폴백).
    static func classify(memo: String, candidates: [Candidate], apiKey: String) async -> Int? {
        guard !candidates.isEmpty else { return -1 }
        var list = "기존 주제 목록:\n"
        for (i, c) in candidates.enumerated() {
            list += "[\(i)] \(c.name)\n"
            for s in c.snippets.prefix(2) { list += "    · \(s)\n" }
        }
        list += "\n새 메모: \(memo)"

        do {
            var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            req.httpMethod = "POST"
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.setValue("application/json", forHTTPHeaderField: "content-type")
            let body: [String: Any] = [
                "model": model, "max_tokens": 60, "system": system,
                "messages": [["role": "user", "content": list]],
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let text = (json?["content"] as? [[String: Any]])?
                .compactMap { $0["text"] as? String }.joined() ?? ""
            return parseMatch(text, count: candidates.count)
        } catch { return nil }
    }

    // {"match": n} 우선, 실패 시 본문 '전체가 정수'일 때만 채택. 범위 밖이면 -1(새 주제).
    // 본문 아무 곳의 숫자를 줍지 않는다("후보 2는 가깝지만 -1을 골라" → 2로 오인하는 일 방지).
    private static func parseMatch(_ text: String, count: Int) -> Int? {
        if let d = text.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let m = obj["match"] as? Int {
            return (m >= 0 && m < count) ? m : -1
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let m = Int(trimmed) {
            return (m >= 0 && m < count) ? m : -1
        }
        return nil
    }
}
