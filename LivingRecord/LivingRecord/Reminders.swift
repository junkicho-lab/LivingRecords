import Foundation
import Observation
import UserNotifications

// S13 — 저녁 회고 리마인더. 매일 정한 시각에 '오늘을 한 줄로' 로컬 알림. 탭하면 포착 화면으로.
// 알림은 기기 안에서만(로컬). 외부 전송 없음 — 프라이버시 원칙 유지.
@Observable
final class ReminderStore {
    static let id = "eveningReview"
    private let kEnabled = "reminderEnabled", kHour = "reminderHour", kMinute = "reminderMinute"

    private(set) var enabled: Bool
    var hour: Int   { didSet { UserDefaults.standard.set(hour, forKey: kHour); rescheduleIfOn() } }
    var minute: Int { didSet { UserDefaults.standard.set(minute, forKey: kMinute); rescheduleIfOn() } }

    init() {
        enabled = UserDefaults.standard.bool(forKey: kEnabled)
        hour = (UserDefaults.standard.object(forKey: kHour) as? Int) ?? 21   // 기본 오후 9시
        minute = UserDefaults.standard.integer(forKey: kMinute)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var timeAsDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
    func setTime(_ d: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        hour = c.hour ?? hour
        minute = c.minute ?? minute
    }

    // 토글: 켜면 권한 요청 후 스케줄, 끄면 취소.
    func setEnabled(_ on: Bool) {
        if on {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.enabled = granted
                    UserDefaults.standard.set(granted, forKey: self.kEnabled)
                    if granted { self.schedule() }
                }
            }
        } else {
            enabled = false
            UserDefaults.standard.set(false, forKey: kEnabled)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.id])
        }
    }

    private func rescheduleIfOn() { if enabled { schedule() } }

    private func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.id])
        let content = UNMutableNotificationContent()
        content.title = "오늘을 한 줄로"
        content.body = "오늘 가장 마음에 남은 생각을 포착해 볼까요?"
        content.sound = .default
        var when = DateComponents(); when.hour = hour; when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.id, content: content, trigger: trigger))
    }
}

// 알림 탭 → 포착 화면으로(자동 녹음은 안 함, 사용자가 말할지 쓸지 선택). 포그라운드에서도 배너 표시.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        await MainActor.run { AppLaunchState.shared.openCapture = true }
    }
}
