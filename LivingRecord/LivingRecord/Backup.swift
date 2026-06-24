import Foundation
import SwiftUI
import SwiftData
import CryptoKit
import UniformTypeIdentifiers

// post-v4 — 사용자 주도 암호화 백업/복원(concept §3-12). 전체 데이터를 JSON→암호구절로 키 유도(HKDF)
// →AES-GCM 암호화 파일로. 봉인 포함(사용자 소유 암호화 백업) — 끄집어내는 건 사용자 선택.

// MARK: - 직렬화 DTO (관계는 ID로)
struct BackupFile: Codable {
    var version = 1
    var exportedAt: Date
    var captures: [CaptureDTO]
    var themes: [ThemeDTO]
    var digests: [DigestDTO]
    var decisions: [DecisionDTO]
    var commitments: [CommitmentDTO]
}
struct CaptureDTO: Codable {
    var id: UUID; var text: String; var createdAt: Date; var energy: Double?
    var sealed: Bool; var tagCandidates: [String]; var embedding: [Double]?
    var themeID: UUID?; var sortIndex: Double
    var userConfirmed: Bool?   // 옵셔널 — 이 필드 이전 백업도 디코드되게(없으면 false)
}
struct ThemeDTO: Codable { var id: UUID; var name: String; var stateRaw: String; var pinned: Bool; var createdAt: Date }
struct DigestDTO: Codable {
    var id: UUID; var kindRaw: String; var periodStart: Date; var periodEnd: Date
    var narrative: String; var generatedInCloud: Bool; var createdAt: Date
    var sealedDerived: Bool?   // 옵셔널 — 이 필드 이전 백업도 디코드되게(없으면 false)
}
struct DecisionDTO: Codable { var id: UUID; var themeID: UUID?; var verdictRaw: String; var reason: String?; var createdAt: Date }
struct CommitmentDTO: Codable { var id: UUID; var text: String; var createdAt: Date; var statusRaw: String; var themeID: UUID?; var themeName: String }

// 암호화 봉투(파일에 저장되는 형태): salt + GCM combined(nonce+ct+tag).
private struct Envelope: Codable { var version = 1; var salt: Data; var sealed: Data }

enum BackupError: Error { case wrongPassphraseOrCorrupt, badFile }

enum BackupService {
    // 전체 수집(@MainActor — context 접근)
    @MainActor
    static func gather(context: ModelContext) throws -> BackupFile {
        let caps = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        let themes = (try? context.fetch(FetchDescriptor<Theme>())) ?? []
        let digests = (try? context.fetch(FetchDescriptor<Digest>())) ?? []
        let decisions = (try? context.fetch(FetchDescriptor<Decision>())) ?? []
        let coms = (try? context.fetch(FetchDescriptor<Commitment>())) ?? []
        return BackupFile(
            exportedAt: Date(),
            captures: caps.map { CaptureDTO(id: $0.id, text: $0.text, createdAt: $0.createdAt, energy: $0.energy,
                sealed: $0.sealed, tagCandidates: $0.tagCandidates, embedding: $0.embedding,
                themeID: $0.theme?.id, sortIndex: $0.sortIndex, userConfirmed: $0.userConfirmed) },
            themes: themes.map { ThemeDTO(id: $0.id, name: $0.name, stateRaw: $0.stateRaw, pinned: $0.pinned, createdAt: $0.createdAt) },
            digests: digests.map { DigestDTO(id: $0.id, kindRaw: $0.kindRaw, periodStart: $0.periodStart, periodEnd: $0.periodEnd,
                narrative: $0.narrative, generatedInCloud: $0.generatedInCloud, createdAt: $0.createdAt, sealedDerived: $0.sealedDerived) },
            decisions: decisions.map { DecisionDTO(id: $0.id, themeID: $0.theme?.id, verdictRaw: $0.verdictRaw, reason: $0.reason, createdAt: $0.createdAt) },
            commitments: coms.map { CommitmentDTO(id: $0.id, text: $0.text, createdAt: $0.createdAt, statusRaw: $0.statusRaw, themeID: $0.themeID, themeName: $0.themeName) }
        )
    }

    // 암호구절 → 키(HKDF-SHA256 + 랜덤 salt). 약한 암호 보완.
    private static func key(from passphrase: String, salt: Data) -> SymmetricKey {
        let ikm = SymmetricKey(data: Data(passphrase.utf8))
        return HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt,
                                      info: Data("LivingRecord.backup".utf8), outputByteCount: 32)
    }

    static func encrypt(_ file: BackupFile, passphrase: String) throws -> Data {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let plain = try enc.encode(file)
        var salt = Data(count: 16)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        let sealed = try AES.GCM.seal(plain, using: key(from: passphrase, salt: salt)).combined!
        return try JSONEncoder().encode(Envelope(salt: salt, sealed: sealed))
    }

    static func decrypt(_ data: Data, passphrase: String) throws -> BackupFile {
        guard let env = try? JSONDecoder().decode(Envelope.self, from: data) else { throw BackupError.badFile }
        do {
            let box = try AES.GCM.SealedBox(combined: env.sealed)
            let plain = try AES.GCM.open(box, using: key(from: passphrase, salt: env.salt))
            let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            return try dec.decode(BackupFile.self, from: plain)
        } catch { throw BackupError.wrongPassphraseOrCorrupt }   // 키 틀리면 인증 실패
    }

    // 복원(병합): 같은 id가 이미 있으면 건너뜀. 주제 먼저 → 관계 연결.
    @MainActor
    static func restore(_ file: BackupFile, into context: ModelContext) -> (added: Int, skipped: Int) {
        var added = 0, skipped = 0
        let existingThemes = Dictionary(uniqueKeysWithValues:
            ((try? context.fetch(FetchDescriptor<Theme>())) ?? []).map { ($0.id, $0) })
        var themeByID = existingThemes
        for t in file.themes where themeByID[t.id] == nil {
            let theme = Theme(name: t.name); theme.id = t.id; theme.stateRaw = t.stateRaw
            theme.pinned = t.pinned; theme.createdAt = t.createdAt
            context.insert(theme); themeByID[t.id] = theme; added += 1
        }
        let existingCapIDs = Set(((try? context.fetch(FetchDescriptor<Capture>())) ?? []).map { $0.id })
        for c in file.captures {
            if existingCapIDs.contains(c.id) { skipped += 1; continue }
            let cap = Capture(text: c.text, createdAt: c.createdAt, energy: c.energy, sealed: c.sealed)
            cap.id = c.id; cap.tagCandidates = c.tagCandidates; cap.embedding = c.embedding
            cap.sortIndex = c.sortIndex; cap.theme = c.themeID.flatMap { themeByID[$0] }
            cap.userConfirmed = c.userConfirmed ?? false
            context.insert(cap); added += 1
        }
        let existingDigIDs = Set(((try? context.fetch(FetchDescriptor<Digest>())) ?? []).map { $0.id })
        for d in file.digests where !existingDigIDs.contains(d.id) {
            let dig = Digest(kind: DigestKind(rawValue: d.kindRaw) ?? .daily, periodStart: d.periodStart,
                             periodEnd: d.periodEnd, narrative: d.narrative, generatedInCloud: d.generatedInCloud)
            dig.id = d.id; dig.createdAt = d.createdAt; dig.sealedDerived = d.sealedDerived ?? false
            context.insert(dig); added += 1
        }
        let existingDecIDs = Set(((try? context.fetch(FetchDescriptor<Decision>())) ?? []).map { $0.id })
        for d in file.decisions where !existingDecIDs.contains(d.id) {
            let dec = Decision(theme: d.themeID.flatMap { themeByID[$0] },
                               verdict: Verdict(rawValue: d.verdictRaw) ?? .hold, reason: d.reason)
            dec.id = d.id; dec.createdAt = d.createdAt; context.insert(dec); added += 1
        }
        let existingComIDs = Set(((try? context.fetch(FetchDescriptor<Commitment>())) ?? []).map { $0.id })
        for c in file.commitments where !existingComIDs.contains(c.id) {
            let com = Commitment(text: c.text, themeID: c.themeID, themeName: c.themeName, createdAt: c.createdAt)
            com.id = c.id; com.statusRaw = c.statusRaw; context.insert(com); added += 1
        }
        try? context.save()
        return (added, skipped)
    }
}

// fileExporter용 문서 래퍼.
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json, .data]
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
