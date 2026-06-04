import SwiftUI
import SwiftData

// S1/S2 — 기록 목록. 최신순 + 봉인 자물쇠 + 에너지 막대.
struct CaptureListView: View {
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List(captures) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 6) {
                        if c.sealed {
                            Image(systemName: "lock.fill")
                                .font(.caption).foregroundStyle(.purple)
                        }
                        Text(c.text)
                    }
                    HStack(spacing: 10) {
                        Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                        if let e = c.energy { energyBar(e) }
                    }
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("기록")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .overlay {
                if captures.isEmpty {
                    ContentUnavailableView("아직 포착이 없어요", systemImage: "mic",
                                           description: Text("포착 탭에서 말하거나 입력해 보세요."))
                }
            }
        }
    }

    @ViewBuilder
    private func energyBar(_ e: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "waveform").font(.caption2)
            Capsule()
                .fill(Color.orange.opacity(0.25))
                .frame(width: 44, height: 4)
                .overlay(alignment: .leading) {
                    Capsule().fill(.orange).frame(width: 44 * e, height: 4)
                }
        }
        .foregroundStyle(.orange)
    }
}
