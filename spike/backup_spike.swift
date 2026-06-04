// 스파이크 — 암호화 백업 라운드트립 검증(앱의 BackupService 암호 로직과 동일).
import Foundation
import CryptoKit

struct Payload: Codable, Equatable { var note: String; var nums: [Double]; var when: Date }
struct Envelope: Codable { var version = 1; var salt: Data; var sealed: Data }

func key(_ pass: String, _ salt: Data) -> SymmetricKey {
    HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: Data(pass.utf8)), salt: salt,
                           info: Data("LivingRecord.backup".utf8), outputByteCount: 32)
}
func encrypt(_ p: Payload, _ pass: String) throws -> Data {
    let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
    let plain = try enc.encode(p)
    var salt = Data(count: 16)
    _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
    let sealed = try AES.GCM.seal(plain, using: key(pass, salt)).combined!
    return try JSONEncoder().encode(Envelope(salt: salt, sealed: sealed))
}
func decrypt(_ data: Data, _ pass: String) throws -> Payload {
    let env = try JSONDecoder().decode(Envelope.self, from: data)
    let box = try AES.GCM.SealedBox(combined: env.sealed)
    let plain = try AES.GCM.open(box, using: key(pass, env.salt))
    let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
    return try dec.decode(Payload.self, from: plain)
}

let p = Payload(note: "봉인된 생각 — 한국어 테스트", nums: [0.12, -3.4, 512.0], when: Date(timeIntervalSince1970: 1_700_000_000))
let blob = try encrypt(p, "내-암호-1234")
print("암호화 크기: \(blob.count) bytes, JSON 봉투? \(String(data: blob.prefix(20), encoding: .utf8) != nil)")

let ok = try decrypt(blob, "내-암호-1234")
print(ok == p ? "✅ 라운드트립 일치(정답 암호)" : "❌ 불일치")

do { _ = try decrypt(blob, "틀린암호"); print("❌ 틀린 암호인데 풀림") }
catch { print("✅ 틀린 암호 → 복호화 실패(\(type(of: error)))") }
