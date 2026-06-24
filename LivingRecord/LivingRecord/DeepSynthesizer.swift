import Foundation

// S6b 2단계 — 클라우드 깊은 종합(Claude Sonnet). 증류층만 받는다. 원문은 절대 안 받음.
// (Interfaces의 DeepSynthesizer 프로토콜과 이름 충돌 피하려 Cloud- 접두)
enum CloudSynthesizer {
    static let model = "claude-sonnet-4-6"

    nonisolated static let weeklySystem = "너는 한 주를 같이 돌아보는 친구다. 쉽고 일상적인 말, 짧은 문장으로 쓴다. 추상적·현학적 비유(흐름·줄기·마음의 방향 같은 말)는 피하고 구체적 사실 위주로. 주어진 '주제별 요약'을 보고, 이번 주 무엇이 자주 나왔고 무엇이 늘고 줄었는지, 무엇을 이어가면 좋을지 한국어 5~8문장으로 정리하라. 단순 나열은 말 것."

    static func synthesize(distilled: String, apiKey: String, system: String = weeklySystem) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 900,
            "system": system,
            "messages": [["role": "user", "content": distilled]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "deep", code: -1, userInfo: [NSLocalizedDescriptionKey: "응답 없음"])
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "deep", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Claude 오류 \(http.statusCode): \(msg.prefix(200))"])
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = (json?["content"] as? [[String: Any]])?
            .compactMap { $0["text"] as? String }.joined()
        return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
