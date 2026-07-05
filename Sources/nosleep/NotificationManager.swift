import UserNotifications
import Foundation

@MainActor
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Public scheduling methods
    func scheduleImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error { print("[X] Immediate notification error: \(error)") }
        }
    }

    func scheduleFirstNotification(at time: Date) {
        let content = makeContent(title: "Time to sleep", 
                                  body: "Please shut down your laptop to get some rest.")
        schedule(at: time, identifier: "firstReminder", content: content)
    }
    
    func scheduleTestNotification(after seconds: TimeInterval = 5) {
        let content = makeContent(title: "Test Reminder",
                                  body: "This is a test notification.")
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error { print("[X] Test error: \(error)") }
        }
    }
    
    // MARK: - Private helpers
    
    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
    
    private func schedule(at time: Date, identifier: String, content: UNMutableNotificationContent) {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[X] Error scheduling \(identifier): \(error)")
            } else {
                print("    Scheduled \(identifier) at \(time)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .list])
    }
}
