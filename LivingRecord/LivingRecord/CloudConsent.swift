import Foundation
import Observation
import Security

// S6b — 클라우드 깊은 종합 동의/키. 기본 OFF. 키는 Keychain(사용자가 직접 입력).
@Observable
final class CloudConsent {
    private let enabledKey = "cloudDeepEnabled"
    private let account = "anthropicAPIKey"

    var enabled: Bool { didSet { UserDefaults.standard.set(enabled, forKey: enabledKey) } }

    init() { enabled = UserDefaults.standard.bool(forKey: enabledKey) }

    var hasAPIKey: Bool { Keychain.get(account) != nil }
    var apiKey: String? { Keychain.get(account) }
    func setAPIKey(_ k: String) {
        let t = k.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { Keychain.delete(account) } else { Keychain.set(t, account: account) }
    }
    /// 클라우드 전송 가능 조건: 토글 ON + 키 존재.
    var canSendToCloud: Bool { enabled && hasAPIKey }
}

// 최소 Keychain 래퍼.
enum Keychain {
    static func set(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
        var add = q; add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }
    static func get(_ account: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrAccount as String: account,
                                 kSecReturnData as String: true,
                                 kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }
    static func delete(_ account: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                       kSecAttrAccount as String: account] as CFDictionary)
    }
}
