// 스파이크 S8-b — 의도 감지: FM 단독(yes 쏠림) 대신 '의도 어미 결정적 게이트' 병용 비교.
// A=FM만, B=어미 게이트만, C=게이트 AND FM. 과감지를 줄이는 게 목표(v1 교훈: 보수적+결정적).
import Foundation
import FoundationModels

@Generable
struct Intention {
    @Guide(description: "화자가 '앞으로 직접 하겠다'고 다짐/계획한 행동이 분명히 있으면 true. 단순 관찰·감정·과거 사실이면 false. 애매하면 false.")
    let hasIntention: Bool
    @Guide(description: "의도가 있으면 그 행동을 짧은 한국어 명사구로(예: '아침 글쓰기'). 없으면 빈 문자열.")
    let phrase: String
}

// 결정적 게이트: 한국어 의도·다짐 어미/표현(보수적, 단어 경계 무관 substring).
let markers = ["겠", "해야", "하자", "해보자", "해 보자", "볼까", "ㄹ까",
               "봐야지", "야지", "려고", "ㄹ래", "을래", "를래", "시작하", "다짐"]
func hasMarker(_ t: String) -> Bool { markers.contains { t.contains($0) } }

func fmDetect(_ memo: String) async -> (Bool, String, Bool) {
    guard case .available = SystemLanguageModel.default.availability else { return (false, "", false) }
    do {
        let s = LanguageModelSession(instructions:
            "한국어 메모에서 화자가 '앞으로 직접 하겠다'고 다짐/계획한 행동이 있는지만 본다. 일어난 일·느낌·평가는 의도가 아니다(false). 의도가 분명할 때만 true.")
        let r = try await s.respond(to: memo, generating: Intention.self)
        return (r.content.hasIntention, r.content.phrase, false)
    } catch { return (false, "", "\(error)".contains("guardrail")) }
}

let tests: [(String, Bool)] = [
    ("다음 주엔 아침마다 30분씩 글쓰기를 해봐야겠다.", true),
    ("오늘 운동을 하고 나니 머리가 맑아졌다.", false),
    ("수업에서 발표 방식을 바꿔서 계속 밀고 가야겠다.", true),
    ("아이들이 텃밭을 가꾸니 다들 즐거워했다.", false),
    ("내일부터 일기를 다시 쓰기 시작하자.", true),
    ("학부모 응대가 너무 스트레스다.", false),
    ("이 책을 끝까지 읽고 정리해 봐야지.", true),
    ("비가 와서 산책을 못 나갔다.", false),
    ("유튜브 채널을 한번 만들어볼까 고민 중이다.", true),
    ("오늘 회의가 길어서 피곤했다.", false),
]

let sem = DispatchSemaphore(value: 0)
Task {
    var aOK = 0, bOK = 0, cOK = 0
    for (memo, expect) in tests {
        let (fm, phrase, _) = await fmDetect(memo)
        let gate = hasMarker(memo)
        let a = fm, b = gate, c = gate && fm
        if a == expect { aOK += 1 }
        if b == expect { bOK += 1 }
        if c == expect { cOK += 1 }
        print("기대\(expect ? "✓" : "·") A=\(a ? "T" : "F") B=\(b ? "T" : "F") C=\(c ? "T" : "F")  '\(phrase)'  | \(memo.prefix(22))")
    }
    print("\nA(FM만) \(aOK)/10  B(게이트만) \(bOK)/10  C(게이트&FM) \(cOK)/10")
    sem.signal()
}
_ = sem.wait(timeout: .now() + 240)
