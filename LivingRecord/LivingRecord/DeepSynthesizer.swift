import Foundation

// S6b 2단계 — 클라우드 깊은 종합(Claude Sonnet). 증류층만 받는다. 원문은 절대 안 받음.
// (Interfaces의 DeepSynthesizer 프로토콜과 이름 충돌 피하려 Cloud- 접두)
enum CloudSynthesizer {
    static let model = "claude-sonnet-4-6"

    nonisolated static let weeklySystem = "너는 한 주를 담담히 지켜본 관찰자다. 감탄·격려·평가 없이, 본 것을 차분한 평서문(~다)으로 적는다. 쉬운 말, 짧은 문장. '흐름·줄기·마음의 방향' 같은 추상적·현학적 비유는 쓰지 않는다. 주어진 '주제별 요약'을 보고 이번 주 전반의 인상과 무엇을 이어가면 좋을지 한국어 3~5문장으로 적는다. 개별 주제를 길게 나열하지 말 것."

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
