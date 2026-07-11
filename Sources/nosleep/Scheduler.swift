import Foundation
import UserNotifications

@MainActor
class Scheduler {
    static let shared = Scheduler()
    private let settings = AppSettings.shared
    private let notificationManager = NotificationManager.shared
    private var timer: Timer?
    private var nextRepeatTime: Date?
    private let checkInterval: TimeInterval = 30 // seconds

    // MARK: - Public

    func reschedule() {
        print("    Scheduler.reschedule() called")
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("    Removed all pending notifications")

        center.getNotificationSettings { settings in
            print("    Notification settings: authorizationStatus = \(settings.authorizationStatus.rawValue)")
            guard settings.authorizationStatus == .authorized else {
                print("[X] Not authorized - skipping schedule")
                return
            }
            DispatchQueue.main.async {
                self.schedule()
            }
        }
    }

    // MARK: - Private scheduling

    private func schedule() {
        let calc = makeCalculator()
        // First notification
        if settings.enableFirst, let first = calc.nextFirstNotification() {
            notificationManager.scheduleFirstNotification(at: first)
        }

        // Repeating
        if settings.enableRepeat, let repeatInfo = calc.nextRepeat() {
            nextRepeatTime = repeatInfo.nextTime
            startTimer()
        } else {
            nextRepeatTime = nil
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndFire()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkAndFire() {
        guard settings.enableRepeat else {
            timer?.invalidate()
            timer = nil
            return
        }

        let now = Date()
        guard let next = nextRepeatTime else { return }

        // Only act if we've passed the scheduled fire time
        guard now >= next else { return }

        // Use the calculator to get the current state
        let calc = makeCalculator(now: now)

        // Get the current (or next) window
        guard let window = calc.currentWindow() else {
            // Shouldn't happen if enableRepeat is true, but just in case
            nextRepeatTime = nil
            timer?.invalidate()
            timer = nil
            return
        }

        // Are we still inside the active window?
        if now >= window.start && now < window.end {
            // We missed a notification - fire one now
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let timeString = formatter.string(from: now)
            notificationManager.scheduleImmediateNotification(
                title: "Still awake?",
                body: "It's already \(timeString). It's time to stop!"
            )
            print("Fired notification at \(timeString)")
        }

        // Compute the next fire time
        if let repeatInfo = calc.nextRepeat() {
            nextRepeatTime = repeatInfo.nextTime
            print("Next repeat scheduled at: \(repeatInfo.nextTime)")
        } else {
            nextRepeatTime = nil
            timer?.invalidate()
            timer = nil
            print("No future repeat, timer stopped.")
        }
    }

    // MARK: - Helpers

    private func makeCalculator(now: Date = Date()) -> ScheduleCalculator {
        return ScheduleCalculator(
            enableFirst: settings.enableFirst,
            enableRepeat: settings.enableRepeat,
            firstTime: settings.firstTime,
            startTime: settings.startTime,
            endTime: settings.endTime,
            intervalMinutes: settings.intervalMinutes,
            now: now,
            calendar: .current
        )
    }
}