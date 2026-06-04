import Foundation
import SwiftData

// 되살아남 — 묻지 않아도 과거가 안부를 묻는다('생동하는 기록'의 핵심). 하루 한 번, 안정적으로 고른다.
// 반추 함정 방지: 시끄러운 걱정 편향 없이, '잊고 있던' 것을 우선. 봉인 제외.
enum Resurfacer {
    struct Memory: Identifiable {
        let capture: Capture
        let reason: String        // 왜 떠올렸나 (예: "1년 전 오늘", "한동안 잊고 있던")
        var id: PersistentIdentifier { capture.persistentModelID }
    }

    // 하루 단위로 고정된 후보(같은 날 다시 봐도 안 바뀜). 14일보다 오래된 것 중에서.
    @MainActor
    static func daily(context: ModelContext, now: Date = .now) -> Memory? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let cutoff = cal.date(byAdding: .day, value: -14, to: today) else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        let pool = all.filter { !$0.sealed && $0.createdAt < cutoff }
        guard !pool.isEmpty else { return nil }

        // 1순위: 'N년/개월 전 오늘'(같은 월·일). 있으면 그중 가장 오래된 것.
        let anniversaries = pool.filter {
            let c = cal.dateComponents([.month, .day], from: $0.createdAt)
            let t = cal.dateComponents([.month, .day], from: today)
            return c.month == t.month && c.day == t.day
        }
        if let pick = anniversaries.min(by: { $0.createdAt < $1.createdAt }) {
            return Memory(capture: pick, reason: anniversaryLabel(pick.createdAt, now: now, cal: cal))
        }

        // 2순위: '잊고 있던' 것. 그날(일 단위)로 안정적인 의사 난수 인덱스로 하나 고름(고정).
        let daySeed = Int(today.timeIntervalSince1970 / 86_400)
        let idx = ((daySeed % pool.count) + pool.count) % pool.count
        let sorted = pool.sorted { $0.createdAt < $1.createdAt }   // 결정적 순서
        let pick = sorted[idx]
        let days = cal.dateComponents([.day], from: pick.createdAt, to: now).day ?? 0
        return Memory(capture: pick, reason: "한동안 잊고 있던 · \(days)일 전")
    }

    private static func anniversaryLabel(_ date: Date, now: Date, cal: Calendar) -> String {
        let years = cal.dateComponents([.year], from: date, to: now).year ?? 0
        if years >= 1 { return "\(years)년 전 오늘" }
        let months = cal.dateComponents([.month], from: date, to: now).month ?? 0
        return months >= 1 ? "\(months)개월 전 오늘" : "얼마 전 오늘"
    }
}
