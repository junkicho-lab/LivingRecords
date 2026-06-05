import SwiftUI

// 기간 필터 — 기록·정리 탭에서 쌓인 자료를 시간으로 좁혀 보기. 칩(오늘/1주/1개월/전체/기간) 공통 컴포넌트.
struct DateRange: Equatable {
    enum Kind: String, CaseIterable, Identifiable {
        case all = "전체", today = "오늘", week = "1주", month = "1개월", custom = "기간"
        var id: String { rawValue }
    }
    var kind: Kind = .all
    var from: Date
    var to: Date

    init() {
        let now = Date()
        to = now
        from = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
    }

    func contains(_ d: Date, now: Date = Date()) -> Bool {
        let cal = Calendar.current
        switch kind {
        case .all:   return true
        case .today: return cal.isDate(d, inSameDayAs: now)
        case .week:  return d >= (cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: now)) ?? now)
        case .month: return d >= (cal.date(byAdding: .month, value: -1, to: cal.startOfDay(for: now)) ?? now)
        case .custom:
            let lo = cal.startOfDay(for: from)
            let hi = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: to)) ?? to
            return d >= lo && d < hi
        }
    }
}

struct DateFilterBar: View {
    @Binding var range: DateRange

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRange.Kind.allCases) { k in
                        let on = range.kind == k
                        Button { range.kind = k } label: {
                            Text(k.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(on ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
                                .foregroundStyle(on ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            if range.kind == .custom {
                HStack(spacing: 8) {
                    DatePicker("", selection: $range.from, in: ...range.to, displayedComponents: .date).labelsHidden()
                    Text("~").foregroundStyle(.secondary)
                    DatePicker("", selection: $range.to, in: range.from..., displayedComponents: .date).labelsHidden()
                }
                .font(.caption)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.bar)
    }
}
