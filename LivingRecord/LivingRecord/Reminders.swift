import Foundation
import Observation
import SwiftData
import UserNotifications

// S13 + 되새김 — 매일 정한 시각 알림에 그날의 '되새김'(과거가 안부)을 실어 진짜 push로.
// 반복 알림은 내용 고정이라, 앞으로 7일치를 각각 그날 되새김 내용으로 미리 예약하고 앱 활성 때 갱신.
@MainActor
@Observable
final class ReminderStore {
    private let kEnabled = "reminderEnabled", kHour = "reminderHour", kMinute = "reminderMinute"
    private static let horizon = 7   // 며칠 앞까지 미리 예약

    private(set) var enabled: Bool
    private(set) var hour: Int
    private(set) var minute: Int

    init() {
        enabled = UserDefaults.standard.bool(forKey: kEnabled)
        hour = (UserDefaults.standard.object(forKey: kHour) as? Int) ?? 21
        minute = UserDefaults.standard.integer(forKey: kMinute)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var timeAsDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    func setEnabled(_ on: Bool, context: ModelContext) {
        guard on else {
            enabled = false
            UserDefaults.standard.set(false, forKey: kEnabled)
            cancelAll()
            return
        }
        Task { @MainActor in   // MainActor 격리 → context 캡처가 @Sendable 경계를 넘지 않음
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            enabled = granted
            UserDefaults.standard.set(granted, forKey: kEnabled)
            if granted { reschedule(context: context) }
        }
    }

    func setTime(_ d: Date, context: ModelContext) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        hour = c.hour ?? hour; minute = c.minute ?? minute
        UserDefaults.standard.set(hour, forKey: kHour); UserDefaults.standard.set(minute, forKey: kMinute)
        reschedule(context: context)
    }

    private func cancelAll() {
        let ids = ["eveningReview"] + (0..<Self.horizon).map { "eveningReview-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // 앞으로 horizon일치를 각각 그날의 되새김 내용으로 (비반복) 예약. 앱 활성 시 호출해 최신 유지.
    @MainActor
    func reschedule(context: ModelContext) {
        guard enabled else { return }
        let center = UNUserNotificationCenter.current()
        cancelAll()
        let cal = Calendar.current
        for offset in 0..<Self.horizon {
            guard let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: .now)) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour; comps.minute = minute
            if offset == 0, let fire = cal.date(from: comps), fire <= Date() { continue }   // 오늘 시각 지났으면 건너뜀

            let content = UNMutableNotificationContent()
            content.sound = .default
            let noon = cal.date(byAdding: .hour, value: 12, to: day) ?? day
            if let m = Resurfacer.daily(context: context, now: noon) {
                content.title = "오늘의 되새김"
                content.body = "\(m.reason) — \(snippet(m.capture.text))"
                content.userInfo = ["dest": "insights"]
            } else {
                content.title = "오늘을 한 줄로"
                content.body = "오늘 가장 마음에 남은 생각을 포착해 볼까요?"
                content.userInfo = ["dest": "capture"]
            }
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "eveningReview-\(offset)", content: content, trigger: trigger))
        }
    }

    private func snippet(_ t: String) -> String {
        let s = t.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.count > 40 ? String(s.prefix(40)) + "…" : s
    }
}

// 알림 탭 → 목적지(되새김=흐름 / 일반=포착)로. 포그라운드에서도 배너 표시.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let dest = response.notification.request.content.userInfo["dest"] as? String
        await MainActor.run {
            if dest == "insights" { AppLaunchState.shared.openInsights = true }
            else { AppLaunchState.shared.openCapture = true }
        }
    }
}
