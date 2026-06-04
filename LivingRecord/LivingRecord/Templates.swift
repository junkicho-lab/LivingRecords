import Foundation
import SwiftData
import Observation

// post-v4 — 정리 템플릿. 종류별(일/주/기간) 기본 틀은 유지하고, 활성 템플릿의 '스타일 지시'를 덧붙인다.
// 프리셋(코드 상수) + 사용자 자유 작성(CustomTemplate). 활성 하나를 골라 모든 정리에 적용.
struct BuiltinTemplate: Identifiable { let key, name, directive: String; var id: String { key } }

enum Templates {
    static let activeKeyDefault = "builtin:warm"
    static let builtins: [BuiltinTemplate] = [
        .init(key: "warm",      name: "따뜻한 통찰",  directive: "따뜻하되 구체적으로, 마음의 흐름을 짚는 통찰 중심으로 써라."),
        .init(key: "brief",     name: "간결 요약",    directive: "군더더기 없이 핵심만 3~4문장으로 짧게 써라."),
        .init(key: "questions", name: "질문 중심",    directive: "단정하기보다, 스스로 더 돌아볼 질문을 2~3개 곁들여라."),
        .init(key: "action",    name: "행동 제안",    directive: "무엇을 이어가고 무엇을 놓을지 구체적인 다음 행동을 제안하라."),
    ]

    // 활성 템플릿의 스타일 지시. custom: UUID면 DB에서, builtin: key면 상수에서. 기본 warm.
    @MainActor
    static func activeDirective(context: ModelContext) -> String {
        let key = UserDefaults.standard.string(forKey: "activeTemplateKey") ?? activeKeyDefault
        if key.hasPrefix("custom:"), let id = UUID(uuidString: String(key.dropFirst(7))),
           let t = ((try? context.fetch(FetchDescriptor<CustomTemplate>())) ?? []).first(where: { $0.id == id }) {
            return t.directive
        }
        let k = key.hasPrefix("builtin:") ? String(key.dropFirst(8)) : "warm"
        return (builtins.first { $0.key == k } ?? builtins[0]).directive
    }
}

// 활성 선택 상태(뷰 갱신용). 실제 지시문 해석은 Templates.activeDirective.
@Observable
final class TemplateStore {
    var activeKey: String { didSet { UserDefaults.standard.set(activeKey, forKey: "activeTemplateKey") } }
    init() { activeKey = UserDefaults.standard.string(forKey: "activeTemplateKey") ?? Templates.activeKeyDefault }
}
