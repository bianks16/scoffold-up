//
//  NotificationManager.swift
//  ScaffoldUp
//
//  Real local-notification scheduling for the three scaffold reminders:
//  tag re-inspection, storm re-check and rental return. Uses
//  UNUserNotificationCenter (iOS 10+, fully iOS 14 safe). No remote push.
//

import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    enum Reminder: String, CaseIterable {
        case reinspection = "scaffoldup.reinspection"
        case storm        = "scaffoldup.storm"
        case rental       = "scaffoldup.rental"

        var title: String {
            switch self {
            case .reinspection: return "Scaffold re-inspection due"
            case .storm:        return "Storm re-check reminder"
            case .rental:       return "Scaffold rental return"
            }
        }
    }

    @Published var isAuthorized = false

    init() { refreshStatus() }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized
                                     || settings.authorizationStatus == .provisional)
            }
        }
    }

    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    /// Schedule a reminder to fire once at a specific date (re-inspection / rental).
    func scheduleOnce(_ reminder: Reminder, at date: Date, body: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.rawValue])

        // Don't schedule in the past — fire shortly instead so it isn't silently lost.
        let fireDate = date > Date().addingTimeInterval(5) ? date : Date().addingTimeInterval(5)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: reminder.rawValue, content: content, trigger: trigger),
                   withCompletionHandler: nil)
    }

    /// Schedule a reminder after an interval (used for storm re-check window).
    func scheduleAfter(_ reminder: Reminder, seconds: TimeInterval, body: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.rawValue])

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 3), repeats: false)
        center.add(UNNotificationRequest(identifier: reminder.rawValue, content: content, trigger: trigger),
                   withCompletionHandler: nil)
    }

    func cancel(_ reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.rawValue])
    }
    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: Reminder.allCases.map { $0.rawValue })
    }

    /// Fires a one-off confirmation so the user immediately sees it working.
    func sendTest(body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Scaffold Up"
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger),
            withCompletionHandler: nil)
    }
}
