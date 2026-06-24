import Foundation
import SwiftData

// 저녁 알림이 무엇을 실을지 — '무르익은 결정'을 되살아남보다 우선해 사용자에게 보낸다(토론 결론: 결정 > 기억).
// 신호는 이미 WeeklyReview가 계산함(소멸한 다짐·식어가는 줄기). 여기선 고르기만 한다. 거울/확인형 질문.
enum EveningPrompt {
    /// 오늘 띄울 결정 하나(소멸한 다짐 > 식어가는 줄기). 최근에 본 건 건너뜀(반복 피로 방지). 없으면 nil.
    @MainActor
    static func ripeDecision(context: ModelContext, now: Date) -> (themeID: UUID, question: String)? {
        for c in WeeklyReview.commitments(context: context, now: now)
        where c.status == .faded {
            if let tid = c.themeID, !snoozed(tid, now: now) {
                return (tid, "‘\(c.text)’ 다짐이 잠잠해졌어요. 놓아줄까요?")
            }
        }
        for cl in WeeklyReview.coolingThemes(context: context, now: now)
        where !snoozed(cl.theme.id, now: now) {
            return (cl.theme.id, "‘\(cl.theme.name)’ \(cl.daysSinceLast)일째 조용해요. 놓아줄까요?")
        }
        return nil
    }

    // 본(또는 미룬) 결정은 한동안 다시 안 띄움. 결정/미루기 시 호출.
    static func snooze(_ id: UUID, days: Int = 7) {
        let until = Calendar.current.date(byAdding: .day, value: days, to: .now)?.timeIntervalSince1970 ?? 0
        UserDefaults.standard.set(until, forKey: key(id))
    }
    static func snoozed(_ id: UUID, now: Date) -> Bool {
        UserDefaults.standard.double(forKey: key(id)) > now.timeIntervalSince1970
    }
    private static func key(_ id: UUID) -> String { "decisionSnooze-\(id.uuidString)" }
}
