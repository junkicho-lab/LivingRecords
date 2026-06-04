// 스파이크 ③ — Foundation Models 한국어 태깅·요약 (온디바이스 LLM)
// 실행: swift fm_spike.swift
import Foundation
import FoundationModels

let model = SystemLanguageModel.default
switch model.availability {
case .available:
    print("✅ Foundation Models 사용 가능")
case .unavailable(let reason):
    print("❌ 사용 불가: \(reason)"); exit(2)
}

let capture = "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다고 생각했어."

let sem = DispatchSemaphore(value: 0)
Task {
    do {
        let session = LanguageModelSession(instructions:
            "너는 한국어 생각 메모를 정리한다. 입력에서 (1) 핵심 주제 태그 1~3개, (2) 한 줄 요약을 한국어로만 출력해라.")
        let resp = try await session.respond(to: capture)
        print("\n--- 입력 ---\n\(capture)\n--- 출력 ---\n\(resp.content)")
    } catch {
        print("❌ 생성 에러: \(error)")
    }
    sem.signal()
}
if sem.wait(timeout: .now() + 60) == .timedOut { print("⏱️ 타임아웃"); exit(3) }
