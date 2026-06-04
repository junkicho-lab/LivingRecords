import SwiftUI
import SwiftData

// S1 — 기록 목록. 최신순. (분류/에너지는 이후 슬라이스)
struct CaptureListView: View {
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]

    var body: some View {
        NavigationStack {
            List(captures) { c in
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.text)
                    Text(c.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("기록")
            .overlay {
                if captures.isEmpty {
                    ContentUnavailableView("아직 포착이 없어요", systemImage: "mic",
                                           description: Text("포착 탭에서 말하거나 입력해 보세요."))
                }
            }
        }
    }
}
