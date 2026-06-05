import Foundation

// S6b 2단계 — 클라우드 깊은 종합(Claude Sonnet). 증류층만 받는다. 원문은 절대 안 받음.
// (Interfaces의 DeepSynthesizer 프로토콜과 이름 충돌 피하려 Cloud- 접두)
enum CloudSynthesizer {
    static let model = "claude-sonnet-4-6"

    nonisolated static let weeklySystem = "너는 사려 깊은 회고 도우미다. 주어진 한 주의 '주제별 요약'을 보고 흐름·반복·발전을 통찰하고, 무엇을 지속하면 좋을지 따뜻하되 구체적으로 한국어 5~8문장으로 종합하라. 단순 나열 금지."

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
