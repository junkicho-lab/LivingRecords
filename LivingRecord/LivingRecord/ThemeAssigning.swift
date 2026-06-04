import Foundation
import FoundationModels

// S4b — 주제 배정. 번호(index) 선택은 기기 FM이 0으로 쏠리는 편향 → 주제별 "같은 분야?" Bool 판단으로 교체.
// (spike/binary_spike: 김치찌개·등산·운동화 모두 false=과병합 안 함, 보수적)
@Generable
struct SameTopic {
    @Guide(description: "메모가 이 주제와 같은 분야·소재면 true, 다르면 false. 확실하지 않으면 false.")
    let same: Bool
}

enum ThemeAssigner {
    /// 반환: 0..<themeNames.count = 기존 주제 / -1 = 새 주제 / -2 = FM 불가(→ 새 주제 처리)
    static func assign(_ memo: String, themeNames: [String]) async -> Int {
        guard !themeNames.isEmpty else { return -1 }
        guard case .available = SystemLanguageModel.default.availability else { return -2 }
        // 각 주제와 '같은 분야인가'를 순서대로 판단, 첫 true에 배정. (향후 임베딩 top-K로 후보 축소)
        for (i, name) in themeNames.enumerated() {
            if await sameTopic(memo, theme: name) { return i }
        }
        return -1
    }

    private static func sameTopic(_ memo: String, theme: String) async -> Bool {
        do {
            let s = LanguageModelSession(instructions:
                "메모가 주어진 주제와 '같은 분야/소재'인지 판단한다. 분야가 다르면 false. 애매하면 false.")
            let r = try await s.respond(to: "주제: \(theme)\n메모: \(memo)", generating: SameTopic.self)
            return r.content.same
        } catch {
            return false   // 가드레일/에러 → 같은 주제 아님(보수적)
        }
    }
}
