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
        print("Scheduling notifications:")
        let now = Date()
        
        // ---- First notification (one‑time, scheduled) ----
        if settings.enableFirst {
            let first = todayDate(from: settings.firstTime)
            let finalFirst = first < now ? Calendar.current.date(byAdding: .day, value: 1, to: first)! : first
            print("First notification at: \(finalFirst)")
            notificationManager.scheduleFirstNotification(at: finalFirst)
        }
        
        // ---- Repeating notifications (timer‑based) ----
        if settings.enableRepeat {
            // Cancel any existing timer
            timer?.invalidate()
            timer = nil
            
            // Compute the next repeat time from now
            let info = computeNextRepeatTime(from: now)
            if let next = info.nextTime {
                nextRepeatTime = next
                print("Next repeat at: \(next)")
                startTimer()
            } else {
                print("No upcoming repeat (window ended or not active)")
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndFire()
            }
        }
        // Ensure timer fires when app is in background
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

        // If we've passed the scheduled time, we need to decide if we should fire
        if now >= next {
            // Check if we are still inside the active window
            let window = computeCurrentWindow(now: now)
            if now >= window.start && now < window.end {
                // Fire the notification with current time
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                let timeString = formatter.string(from: now)
                notificationManager.scheduleImmediateNotification(
                    title: "Still awake?",
                    body: "It's already \(timeString). It's time to stop!"
                )
                // Compute the next repeat after now
                if let newNext = computeNextRepeatTime(from: now).nextTime {
                    nextRepeatTime = newNext
                    print("Next repeat scheduled at: \(newNext)")
                } else {
                    // No more repeats today (window ended)
                    nextRepeatTime = nil
                    timer?.invalidate()
                    timer = nil
                    print("Repeating window ended, timer stopped.")
                }
            } else {
                // We are outside the window - compute the next window start
                if let newNext = computeNextRepeatTime(from: now).nextTime {
                    nextRepeatTime = newNext
                    print("Outside window, next repeat at: \(newNext)")
                } else {
                    nextRepeatTime = nil
                    timer?.invalidate()
                    timer = nil
                    print("No future repeat, timer stopped.")
                }
            }
        }
        // If now < next, do nothing - wait
    }

    // MARK: - Time calculation helpers

    private struct RepeatInfo {
        let nextTime: Date?
        let windowStart: Date
        let windowEnd: Date
        let intervalMinutes: Int
    }

    private func computeNextRepeatTime(from now: Date) -> RepeatInfo {
        let calendar = Calendar.current
        let startToday = todayDate(from: settings.startTime)
        let endToday = todayDate(from: settings.endTime)
        let interval = settings.intervalMinutes
        
        // Determine current window
        var windowStart: Date
        var windowEnd: Date
        
        if settings.endTime < settings.startTime {
            // Crosses midnight
            let startYesterday = calendar.date(byAdding: .day, value: -1, to: startToday)!
            let endTodayPlusOne = calendar.date(byAdding: .day, value: 1, to: endToday)!
            if now >= startYesterday && now < endToday {
                windowStart = startYesterday
                windowEnd = endToday
            } else if now >= startToday && now < endTodayPlusOne {
                windowStart = startToday
                windowEnd = endTodayPlusOne
            } else if now < startToday {
                windowStart = startToday
                windowEnd = endTodayPlusOne
            } else {
                windowStart = calendar.date(byAdding: .day, value: 1, to: startToday)!
                windowEnd = calendar.date(byAdding: .day, value: 1, to: endTodayPlusOne)!
            }
        } else {
            // Does not cross midnight
            if now >= startToday && now < endToday {
                windowStart = startToday
                windowEnd = endToday
            } else if now < startToday {
                windowStart = startToday
                windowEnd = endToday
            } else {
                windowStart = calendar.date(byAdding: .day, value: 1, to: startToday)!
                windowEnd = calendar.date(byAdding: .day, value: 1, to: endToday)!
            }
        }
        
        // Now compute the next repeat time >= now
        var nextTime: Date? = nil
        if now < windowStart {
            // Window hasn't started yet → first repeat is at windowStart
            nextTime = windowStart
        } else if now >= windowStart && now < windowEnd {
            // Inside the window - compute next interval
            let intervalSeconds = TimeInterval(interval * 60)
            let elapsed = now.timeIntervalSince(windowStart)
            let intervalsElapsed = Int(elapsed / intervalSeconds)
            let candidate = windowStart.addingTimeInterval(TimeInterval((intervalsElapsed + 1) * interval * 60))
            if candidate < windowEnd {
                nextTime = candidate
            } else {
                // No more repeats today - schedule tomorrow's start
                nextTime = calendar.date(byAdding: .day, value: 1, to: windowStart)!
            }
        } else {
            // Past the window - schedule tomorrow's start
            nextTime = calendar.date(byAdding: .day, value: 1, to: windowStart)!
        }
        
        return RepeatInfo(nextTime: nextTime, windowStart: windowStart, windowEnd: windowEnd, intervalMinutes: interval)
    }

    private func computeCurrentWindow(now: Date) -> (start: Date, end: Date) {
        let info = computeNextRepeatTime(from: now)
        return (info.windowStart, info.windowEnd)
    }

    private func todayDate(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date())!
    }
}
