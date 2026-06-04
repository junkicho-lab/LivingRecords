import Foundation
import SwiftData

// S0 스캐폴딩 — concept.md §4 데이터 모델. 필드는 슬라이스 진행하며 채워짐(주석의 S# 참고).

enum ThemeState: String, Codable { case active, looping, cooling, decided }   // 활성/맴돎/냉각/결정됨
enum DigestKind: String, Codable { case daily, weekly, period }
enum Verdict: String, Codable { case sustain, hold, drop }                    // 지속/보류/접기

@Model
final class Capture {
    var id: UUID
    var text: String
    var createdAt: Date
    var energy: Double?            // prosody 각성도 점수 (S2)
    var sealed: Bool               // 봉인 (S2)
    var tagCandidates: [String]    // emergent 주제 후보 (S4)
    var embedding: [Double]?       // 512d 임베딩 (S4)
    var theme: Theme?              // 통합된 주제 (S4)
    var sortIndex: Double = 0      // 주제 내 수동 정렬값 (기본=생성시각). 클수록 위.

    init(text: String, createdAt: Date = .now, energy: Double? = nil, sealed: Bool = false) {
        self.id = UUID(); self.text = text; self.createdAt = createdAt
        self.energy = energy; self.sealed = sealed
        self.tagCandidates = []; self.embedding = nil; self.theme = nil
        self.sortIndex = createdAt.timeIntervalSince1970
    }
}

@Model
final class Theme {
    var id: UUID
    var name: String
    var stateRaw: String
    var pinned: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Capture.theme) var captures: [Capture]

    var state: ThemeState {
        get { ThemeState(rawValue: stateRaw) ?? .active }
        set { stateRaw = newValue.rawValue }
    }
    init(name: String, state: ThemeState = .active) {
        self.id = UUID(); self.name = name; self.stateRaw = state.rawValue
        self.pinned = false; self.createdAt = .now; self.captures = []
    }
}

@Model
final class Digest {
    var id: UUID
    var kindRaw: String
    var periodStart: Date
    var periodEnd: Date
    var narrative: String          // 가공된 서술글
    var generatedInCloud: Bool     // 깊은 종합(클라우드) 여부
    var createdAt: Date

    var kind: DigestKind { DigestKind(rawValue: kindRaw) ?? .daily }
    init(kind: DigestKind, periodStart: Date, periodEnd: Date,
         narrative: String = "", generatedInCloud: Bool = false) {
        self.id = UUID(); self.kindRaw = kind.rawValue
        self.periodStart = periodStart; self.periodEnd = periodEnd
        self.narrative = narrative; self.generatedInCloud = generatedInCloud; self.createdAt = .now
    }
}

@Model
final class Decision {
    var id: UUID
    var theme: Theme?
    var verdictRaw: String
    var reason: String?
    var createdAt: Date

    var verdict: Verdict { Verdict(rawValue: verdictRaw) ?? .hold }
    init(theme: Theme?, verdict: Verdict, reason: String? = nil) {
        self.id = UUID(); self.theme = theme; self.verdictRaw = verdict.rawValue
        self.reason = reason; self.createdAt = .now
    }
}
