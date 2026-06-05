import Foundation
import SwiftData

// S0 스캐폴딩 — concept.md §4 데이터 모델. 필드는 슬라이스 진행하며 채워짐(주석의 S# 참고).

enum ThemeState: String, Codable { case active, looping, cooling, decided }   // 활성/맴돎/냉각/결정됨
enum DigestKind: String, Codable { case daily, weekly, period }
enum Verdict: String, Codable { case sustain, hold, drop }                    // 지속/보류/접기
enum CommitmentStatus: String, Codable { case open, surviving, faded }        // 약속: 진행중/살아남음/잠잠해짐 (S8)

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
    var mirrored: Bool = false     // (미사용) 양방향 Obsidian 철회 후 남은 필드 — 마이그레이션 회피 위해 보존

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

// S6b — 클라우드 전송 로그(투명성). 무엇이 언제 나갔나.
@Model
final class Transmission {
    var id: UUID
    var date: Date
    var kind: String       // 예: "weekly"
    var charCount: Int     // 전송한 증류층 글자 수
    init(kind: String, charCount: Int) {
        self.id = UUID(); self.date = .now; self.kind = kind; self.charCount = charCount
    }
}

// S8 — 약속(의도). 포착 속 '하겠다' 의도를 결정적 게이트로 감지해 남김.
// 주제 관계 대신 themeID 스냅샷만 둠 → 포착·주제 삭제 시 댕글링/캐스케이드 없음(생존은 themeID로 조회).
@Model
final class Commitment {
    var id: UUID
    var text: String              // 핵심 의도구(FM 추출, 실패 시 포착 텍스트 폴백)
    var createdAt: Date
    var statusRaw: String
    var themeID: UUID?            // 어느 주제에 속한 다짐인가(생존 판정용)
    var themeName: String         // 표시·미러용 스냅샷

    var status: CommitmentStatus {
        get { CommitmentStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }
    init(text: String, themeID: UUID?, themeName: String, createdAt: Date = .now) {
        self.id = UUID(); self.text = text; self.createdAt = createdAt
        self.statusRaw = CommitmentStatus.open.rawValue
        self.themeID = themeID; self.themeName = themeName
    }
}

// post-v4 — 사용자 자유 작성 정리 템플릿(스타일 지시). 프리셋은 코드 상수, 이건 사용자 것만 저장.
@Model
final class CustomTemplate {
    var id: UUID
    var name: String
    var directive: String      // 정리 글에 덧붙는 스타일/초점 지시
    var createdAt: Date
    init(name: String, directive: String) {
        self.id = UUID(); self.name = name; self.directive = directive; self.createdAt = .now
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
