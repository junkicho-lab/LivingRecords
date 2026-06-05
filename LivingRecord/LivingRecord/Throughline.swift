import Foundation
import SwiftData

// 긴 호흡의 줄기 — 한 번 불타고 끝난 게 아니라 여러 시기에 걸쳐 거듭 돌아온 주제.
// "내가 한결같이 마음 쓴 것." 짧은 폭발(한 주 몰아치기)은 제외하고, 시간을 가로지른 지속만.
struct Throughline: Identifiable {
    let theme: Theme
    let first: Date
    let last: Date
    let count: Int
    let distinctWeeks: Int     // 서로 다른 '주'에 등장한 횟수(시간을 가로지른 정도)
    var spanDays: Int { Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0 }
    var id: PersistentIdentifier { theme.persistentModelID }
}

enum Throughlines {
    static func compute(_ themes: [Theme], limit: Int = 5) -> [Throughline] {
        let cal = Calendar.current
        func weekKey(_ d: Date) -> Int {
            let c = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: d)
            return (c.yearForWeekOfYear ?? 0) * 100 + (c.weekOfYear ?? 0)
        }
        var out: [Throughline] = []
        for t in themes {
            let caps = t.captures
            guard let first = caps.map({ $0.createdAt }).min(),
                  let last = caps.map({ $0.createdAt }).max() else { continue }
            let span = cal.dateComponents([.day], from: first, to: last).day ?? 0
            let weeks = Set(caps.map { weekKey($0.createdAt) }).count
            guard span >= 30, weeks >= 3 else { continue }   // 30일+ 폭 + 3주+ 가로지름 = 줄기
            out.append(Throughline(theme: t, first: first, last: last, count: caps.count, distinctWeeks: weeks))
        }
        return Array(out.sorted { ($0.distinctWeeks, $0.spanDays) > ($1.distinctWeeks, $1.spanDays) }.prefix(limit))
    }
}
