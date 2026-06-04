import SwiftUI
import SwiftData
import Charts

// post-v4 — 흐름 탭. 쌓인 신호를 한눈에: 일별 포착 수 · 에너지 추이 · 주제 분포 + 요약.
struct InsightsView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Capture.createdAt) private var captures: [Capture]
    @Query private var themes: [Theme]

    private let cal = Calendar.current
    private let windowDays = 14

    private var days: [Date] {
        let today = cal.startOfDay(for: .now)
        return (0..<windowDays).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }
    private func sameDay(_ a: Date, _ b: Date) -> Bool { cal.isDate(a, inSameDayAs: b) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if captures.isEmpty {
                    ContentUnavailableView("아직 그릴 게 없어요", systemImage: "chart.bar",
                                           description: Text("포착이 쌓이면 흐름이 보여요."))
                        .padding(.top, 80)
                } else {
                    VStack(spacing: 24) {
                        summary
                        dailyCounts
                        energyTrend
                        topThemes
                    }
                    .padding()
                }
            }
            .navigationTitle("흐름")
        }
    }

    // 요약 카드들
    private var summary: some View {
        let withE = captures.compactMap { $0.energy }
        let avgE = withE.isEmpty ? nil : withE.reduce(0, +) / Double(withE.count)
        let sealed = captures.filter { $0.sealed }.count
        return HStack(spacing: 10) {
            stat("\(captures.count)", "포착")
            stat("\(themes.filter { !$0.captures.isEmpty }.count)", "주제")
            stat(avgE.map { String(format: "%.0f%%", $0 * 100) } ?? "—", "평균 에너지")
            stat("\(sealed)", "봉인")
        }
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // 일별 포착 수
    private var dailyCounts: some View {
        let data = days.map { d in (day: d, count: captures.filter { sameDay($0.createdAt, d) }.count) }
        return card("최근 \(windowDays)일 포착") {
            Chart(data, id: \.day) { e in
                BarMark(x: .value("날", e.day, unit: .day), y: .value("포착", e.count))
                    .foregroundStyle(.blue)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { v in
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            } }
            .frame(height: 150)
        }
    }

    // 에너지 추이(에너지 있는 날의 일평균)
    private var energyTrend: some View {
        let data = days.compactMap { d -> (day: Date, energy: Double)? in
            let es = captures.filter { sameDay($0.createdAt, d) }.compactMap { $0.energy }
            return es.isEmpty ? nil : (d, es.reduce(0, +) / Double(es.count))
        }
        return card("에너지 추이") {
            if data.count < 2 {
                Text("음성 포착이 더 쌓이면 보여요.").font(.caption).foregroundStyle(.secondary).frame(height: 60)
            } else {
                Chart(data, id: \.day) { e in
                    LineMark(x: .value("날", e.day, unit: .day), y: .value("에너지", e.energy))
                        .foregroundStyle(.orange).interpolationMethod(.catmullRom)
                    PointMark(x: .value("날", e.day, unit: .day), y: .value("에너지", e.energy))
                        .foregroundStyle(.orange)
                }
                .chartYScale(domain: 0...1)
                .frame(height: 150)
            }
        }
    }

    // 주제 분포(Top 8)
    private var topThemes: some View {
        let tops = themes.map { (name: $0.name, count: $0.captures.count) }
            .filter { $0.count > 0 }.sorted { $0.count > $1.count }.prefix(8)
        return card("자주 다룬 주제") {
            Chart(Array(tops), id: \.name) { t in
                BarMark(x: .value("수", t.count), y: .value("주제", t.name))
                    .foregroundStyle(.purple)
            }
            .frame(height: max(80, CGFloat(tops.count) * 28))
        }
    }

    private func card<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}
