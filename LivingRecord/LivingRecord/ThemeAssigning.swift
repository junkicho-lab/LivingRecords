import Foundation
import FoundationModels

// S4b — 주제 배정. 번호(index) 선택은 기기 FM이 0으로 쏠리는 편향 → 주제별 "같은 분야?" Bool 판단으로 교체.
// (spike/binary_spike: 김치찌개·등산·운동화 모두 false=과병합 안 함, 보수적)
// 개선: ① 임베딩으로 후보를 top-K로 좁히고(생성순 편향 제거·확장성) ② 이름이 아니라 주제의 '기존 기록'과
//      비교해(내용 기반) ③ 유사도 높은 순으로 보며 FM이 확인하는 '최적' 주제에 배정.
@Generable
struct SameTopic {
    @Guide(description: "새 메모가 이 주제의 기존 기록들과 같은 분야·맥락이면 true, 다르면 false. 확실하지 않으면 false.")
    let same: Bool
}

// 배정 후보(주제)의 값 스냅샷 — SwiftData/MainActor 접근 없이 판단하도록 Consolidation이 구성해 넘김.
struct ThemeCandidate {
    let index: Int          // 호출부 themes 배열에서의 위치(반환값)
    let name: String
    let centroid: [Double]? // member 임베딩 평균(중심화 전). 없으면 순위에서 뒤로.
    let snippets: [String]  // 대표 기록 일부(로컬 FM 판단용, 봉인 제외)
    let confirmedEmbeddings: [[Double]]   // 사용자가 직접 이 주제로 옮긴 포착들의 임베딩(학습 신호)
}

enum ThemeAssigner {
    static let topK = 5     // FM에 물어볼 후보 상한(임베딩으로 추린 뒤)

    /// 반환: 0..<count = 기존 주제 index / -1 = 새 주제 / -2 = FM 불가(→ 새 주제 처리)
    static func assign(_ memo: String, memoEmbedding: [Double]?,
                       candidates: [ThemeCandidate], center: [Double]?) async -> Int {
        guard !candidates.isEmpty else { return -1 }
        guard case .available = SystemLanguageModel.default.availability else { return -2 }

        // ① 임베딩으로 후보를 '거칠게' 좁힌다. (spike ⑥: 유사도 단독은 부정확 → 후보 추리기에만 쓰고 판단은 FM)
        //    점수 = max(주제 중심 유사도, 사용자 확정 범례 중 최고 유사도). 후자가 '교정에서 학습'한 신호 —
        //    사용자가 직접 옮겨둔 포착과 가까우면, 중심이 미지근해도 그 주제를 앞으로 끌어올린다.
        let ranked: [ThemeCandidate]
        if let e = memoEmbedding {
            ranked = candidates
                .map { c -> (ThemeCandidate, Double) in
                    let centroidSim = c.centroid.map { VectorMath.cosCentered(e, $0, center: center) } ?? -2
                    let confirmedSim = c.confirmedEmbeddings
                        .map { VectorMath.cosCentered(e, $0, center: center) }.max() ?? -2
                    return (c, max(centroidSim, confirmedSim))
                }
                .sorted { $0.1 > $1.1 }
                .prefix(topK).map { $0.0 }
        } else {
            ranked = Array(candidates.prefix(topK))   // 임베딩 불가 시 생성순 상위 K
        }

        // ②③ 유사도 높은 순으로 보며, FM이 '같은 주제'라 확인하는 첫(=최적) 후보에 배정.
        for c in ranked {
            if await sameTopic(memo, theme: c) { return c.index }
        }
        return -1
    }

    private static func sameTopic(_ memo: String, theme c: ThemeCandidate) async -> Bool {
        do {
            let s = LanguageModelSession(instructions:
                "새 메모가 주어진 '주제'의 기존 기록들과 같은 분야·맥락에 속하는지 판단한다. 소재가 다르면 false, 애매하면 false.")
            var prompt = "주제 이름: \(c.name)\n"
            if !c.snippets.isEmpty {
                prompt += "이 주제의 기존 기록:\n" + c.snippets.map { "- \($0)" }.joined(separator: "\n") + "\n"
            }
            prompt += "새 메모: \(memo)"
            let r = try await s.respond(to: prompt, generating: SameTopic.self)
            return r.content.same
        } catch {
            return false   // 가드레일/에러 → 같은 주제 아님(보수적)
        }
    }
}
