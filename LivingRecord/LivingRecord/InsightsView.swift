import SwiftUI
import SwiftData
import Charts

// post-v4 — 흐름 탭. 쌓인 신호를 한눈에: 일별 포착 수 · 에너지 추이 · 주제 분포 + 요약.
struct InsightsView: View {
    @Environment(\.modelContext) private var context
    @Environment(VaultStore.self) private var vault
    @Query(sort: \Capture.createdAt) private var captures: [Capture]
    @Query private var themes: [Theme]

    @State private var memory: Resurfacer.Memory?
    @State private var rising: [String] = []     // 떠오르는 주제(이번 주)
    @State private var cooling: [String] = []    // 식어가는 주제
    private let cal = Calendar.current
    private let windowDays = 14

    private var days: [Date] {
        let today = cal.startOfDay(for: .now)
        return (0..<windowDays).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }
    private func sameDay(_ a: Date, _ b: Date) -> Bool { cal.isDate(a, inSameDayAs: b) }

    // 이번 주(최근 7일) vs 지난 주 — 방향 비교용 창.
    private var weekStart: Date { cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: .now)) ?? .now }
    private var prevStart: Date { cal.date(byAdding: .day, value: -13, to: cal.startOfDay(for: .now)) ?? .now }
    private var thisWeek: [Capture] { captures.filter { $0.createdAt >= weekStart } }
    private var prevWeek: [Capture] { captures.filter { $0.createdAt >= prevStart && $0.createdAt < weekStart } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if captures.isEmpty {
                    ContentUnavailableView("아직 그릴 게 없어요", systemImage: "chart.bar",
                                           description: Text("포착이 쌓이면 흐름이 보여요."))
                        .padding(.top, 80)
                } else {
                    VStack(spacing: 24) {
                        headline            // ① 한 줄 결론
                        directionalStats    // ② 이번 주 vs 지난 주
                        flowBoard           // ③ 떠오름 / 식어감
                        if let m = memory { resurfaced(m) }
                        throughlines
                        dailyCounts
                        energyTrend
                        topThemes
                    }
                    .padding()
                }
            }
            .navigationTitle("흐름")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadFlow() }
        }
    }

    // 되새김 — 가만히 있어도 과거가 안부를 묻는 카드.
    private func resurfaced(_ m: Resurfacer.Memory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(m.reason, systemImage: "sparkles").font(.caption).foregroundStyle(.orange)
            Text(m.capture.text).font(.callout)
            HStack(spacing: 8) {
                if let name = m.capture.theme?.name {
                    Text(name).font(.caption2).padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Color.gray.opacity(0.15), in: Capsule()).foregroundStyle(.secondary)
                }
                Text(m.capture.createdAt, format: .dateTime.year().month().day())
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func loadFlow() {
        memory = Resurfacer.daily(context: context)
        let cands = WeeklyReview.candidates(context: context, now: .now)
        rising = cands.filter { $0.trend == .rising }.prefix(4).map { $0.theme.name }
        cooling = WeeklyReview.coolingThemes(context: context, now: .now).prefix(4).map { $0.theme.name }
    }

    // ① 헤드라인 — 결정적 한 줄(LLM 없음). 담담한 관찰자체.
    private var headline: some View {
        var s = "이번 주 \(thisWeek.count)회"
        let lc = prevWeek.count
        if lc > 0 {
            s += thisWeek.count > lc ? " — 지난 주(\(lc))보다 늘었다." :
                 (thisWeek.count < lc ? " — 지난 주(\(lc))보다 줄었다." : " — 지난 주와 비슷하다.")
        } else { s += " 기록되는 중이다." }
        if let top = topTheme(thisWeek) { s += " ‘\(top)’이 가장 자주 나왔다." }
        if let d = energyDelta { s += d > 0.03 ? " 에너지는 오르는 중이다." : (d < -0.03 ? " 에너지는 내리는 중이다." : "") }
        return Text(s).font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // ② 방향 있는 스탯 — 이번 주 vs 지난 주(↑/↓). 누적 합계가 아니라 변화.
    private var directionalStats: some View {
        HStack(spacing: 10) {
            dstat("\(thisWeek.count)", "이번 주 포착", trend(Double(thisWeek.count), Double(prevWeek.count)))
            dstat("\(activeThemes(thisWeek))", "활성 주제", trend(Double(activeThemes(thisWeek)), Double(activeThemes(prevWeek))))
            dstat(energyLabel(avgEnergy(thisWeek)), "에너지", energyDelta.map { trendFromDelta($0, 0.03) })
            dstat(focusText(thisWeek), "집중도", focusTrend)
        }
    }
    private func dstat(_ value: String, _ label: String, _ t: FlowTrend?) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value).font(.title3.bold())
                if let t, t != .flat { Image(systemName: t.icon).font(.caption2.bold()).foregroundStyle(.blue) }
            }
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // ③ 떠오름 / 식어감 — 주간 안 열어도 '이어갈지/놓을지'가 한눈에.
    @ViewBuilder
    private var flowBoard: some View {
        if !rising.isEmpty || !cooling.isEmpty {
            card("지금 흐름") {
                HStack(alignment: .top, spacing: 14) {
                    flowGroup("떠오름", rising, .green, "arrow.up.right")
                    Divider()
                    flowGroup("식어감", cooling, .gray, "arrow.down.right")
                }
            }
        }
    }
    private func flowGroup(_ title: String, _ names: [String], _ color: Color, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.caption.weight(.medium)).foregroundStyle(color)
            if names.isEmpty {
                Text("—").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(names, id: \.self) { n in
                    Text(n).font(.caption).lineLimit(1)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(color.opacity(0.12), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 글랜스 계산(결정적·온디바이스)
    private enum FlowTrend { case up, down, flat
        var icon: String { self == .down ? "arrow.down" : "arrow.up" }
    }
    private func trend(_ now: Double, _ prev: Double) -> FlowTrend? {
        guard prev > 0 else { return nil }   // 비교 기준 없으면 화살표 생략
        let d = now - prev, eps = max(0.5, prev * 0.05)
        return d > eps ? .up : (d < -eps ? .down : .flat)
    }
    private func trendFromDelta(_ d: Double, _ eps: Double) -> FlowTrend { d > eps ? .up : (d < -eps ? .down : .flat) }
    private func avgEnergy(_ caps: [Capture]) -> Double? {
        let es = caps.compactMap { $0.energy }; return es.isEmpty ? nil : es.reduce(0,+)/Double(es.count)
    }
    private var energyDelta: Double? {
        guard let t = avgEnergy(thisWeek), let p = avgEnergy(prevWeek) else { return nil }
        return t - p
    }
    private func energyLabel(_ e: Double?) -> String {
        guard let e else { return "—" }
        return e < 0.4 ? "차분" : (e < 0.7 ? "중간" : "들뜸")
    }
    private func activeThemes(_ caps: [Capture]) -> Int { Set(caps.compactMap { $0.theme?.name }).count }
    private func topTheme(_ caps: [Capture]) -> String? {
        var c: [String: Int] = [:]; for x in caps { if let n = x.theme?.name { c[n, default: 0] += 1 } }
        return c.max { $0.value < $1.value }?.key
    }
    // 집중도 = 상위 3개 주제가 차지하는 비중(높을수록 포커스됨).
    private func focusRatio(_ caps: [Capture]) -> Double? {
        let wt = caps.filter { $0.theme != nil }; guard !wt.isEmpty else { return nil }
        var c: [String: Int] = [:]; for x in wt { c[x.theme!.name, default: 0] += 1 }
        let top3 = c.values.sorted(by: >).prefix(3).reduce(0, +)
        return Double(top3) / Double(wt.count)
    }
    private func focusText(_ caps: [Capture]) -> String { focusRatio(caps).map { "\(Int($0 * 100))%" } ?? "—" }
    private var focusTrend: FlowTrend? {
        guard let t = focusRatio(thisWeek), let p = focusRatio(prevWeek) else { return nil }
        return trendFromDelta(t - p, 0.05)
    }

    // 일별 포착 수 — 오늘 막대 강조 + 7일 평균선(내 평소 대비 위/아래가 한눈에).
    private var dailyCounts: some View {
        let data = days.map { d in (day: d, count: captures.filter { sameDay($0.createdAt, d) }.count) }
        let recent7 = data.suffix(7).map { $0.count }
        let avg7 = recent7.isEmpty ? 0 : Double(recent7.reduce(0, +)) / Double(recent7.count)
        return card("최근 \(windowDays)일 포착") {
            Chart {
                ForEach(data, id: \.day) { e in
                    BarMark(x: .value("날", e.day, unit: .day), y: .value("포착", e.count))
                        .foregroundStyle(cal.isDateInToday(e.day) ? Color.blue : Color.blue.opacity(0.3))
                }
                RuleMark(y: .value("7일 평균", avg7))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("7일 평균 \(String(format: "%.1f", avg7))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { _ in
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
                .chartYAxis {   // 0~1 숫자 대신 차분↔들뜸으로 앵커
                    AxisMarks(values: [0.2, 0.8]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text(d < 0.5 ? "차분" : "들뜸").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
    }

    // 긴 호흡의 줄기 — 여러 시기를 가로질러 이어진 주제
    @ViewBuilder
    private var throughlines: some View {
        let lines = Throughlines.compute(themes)
        if !lines.isEmpty {
            card("오래 이어진 줄기") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(lines) { t in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.theme.name).font(.callout.weight(.medium))
                            Text("\(t.first, format: .dateTime.year().month()) ~ \(t.last, format: .dateTime.year().month()) · \(t.count)회")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("\(t.distinctWeeks)주에 걸쳐 이어짐")
                                .font(.caption2).foregroundStyle(.indigo)
                        }
                    }
                    Text("한 번 불타고 끝난 게 아니라, 여러 시기에 거듭 돌아온 주제예요.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
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
