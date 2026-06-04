// 스파이크 S8 — 자동 의도 감지: 포착 속 '하겠다/해보자' 의도를 FM @Generable로 잡아내고 핵심 의도구 추출.
// 기대: 의도 있는 메모만 hasIntention=true, 핵심 의도구가 깔끔히. 관찰·감정 메모는 false(과감지 적게).
import Foundation
import FoundationModels

@Generable
struct Intention {
    @Guide(description: "이 메모에 앞으로 '하겠다·해보자·시작하자' 같은 본인의 의도/계획/다짐이 담겼으면 true, 단순 관찰·감정·사실 서술이면 false. 애매하면 false.")
    let hasIntention: Bool
    @Guide(description: "의도가 있으면 그 핵심을 짧은 한국어 명사구로(예: '글쓰기 꾸준히 하기'). 없으면 빈 문자열.")
    let phrase: String
}

func detect(_ memo: String) async -> (Bool, String, Bool) {   // (hasIntention, phrase, blocked)
    guard case .available = SystemLanguageModel.default.availability else { return (false, "", false) }
    do {
        let s = LanguageModelSession(instructions:
            "너는 한국어 생각 메모에서 '앞으로 하겠다는 의도/다짐/계획'이 있는지 판단하고, 있으면 핵심 의도만 짧은 명사구로 뽑는다. 관찰·감정·과거 사실만 있으면 의도 없음(false).")
        let r = try await s.respond(to: memo, generating: Intention.self)
        return (r.content.hasIntention, r.content.phrase, false)
    } catch {
        return (false, "", "\(error)".contains("guardrail"))
    }
}

// (메모, 의도 있음 기대)
let tests: [(String, Bool)] = [
    ("다음 주엔 아침마다 30분씩 글쓰기를 해봐야겠다.", true),
    ("오늘 운동을 하고 나니 머리가 맑아졌다.", false),
    ("수업에서 발표 방식을 바꿔서 계속 밀고 가야겠다.", true),
    ("아이들이 텃밭을 가꾸니 다들 즐거워했다.", false),
    ("내일부터 일기를 다시 쓰기 시작하자.", true),
    ("학부모 응대가 너무 스트레스다.", false),
    ("이 책을 끝까지 읽고 정리해 봐야지.", true),
    ("비가 와서 산책을 못 나갔다.", false),
    ("유튜브 채널을 한번 만들어볼까 고민 중이다.", true),   // 약한 의도(애매) — false도 허용
    ("오늘 회의가 길어서 피곤했다.", false),
]

let sem = DispatchSemaphore(value: 0)
Task {
    var ok = 0, blocked = 0
    for (memo, expect) in tests {
        let (has, phrase, block) = await detect(memo)
        if block { blocked += 1 }
        let mark = has == expect ? "✅" : (block ? "🛑" : "❓")
        if has == expect { ok += 1 }
        print("\(mark) 의도=\(has) (기대 \(expect))  구='\(phrase)'  | \(memo.prefix(24))")
    }
    print("\n정확 \(ok)/\(tests.count), 가드레일 차단 \(blocked)")
    sem.signal()
}
_ = sem.wait(timeout: .now() + 240)
