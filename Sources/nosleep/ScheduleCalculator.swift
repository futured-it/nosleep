import Foundation

struct ScheduleCalculator {
    let enableFirst: Bool
    let enableRepeat: Bool
    let firstTime: Date          // time of day (ignore date components)
    let startTime: Date          // time of day
    let endTime: Date            // time of day
    let intervalMinutes: Int
    let now: Date                // reference “current” date
    let calendar: Calendar       // injected for testability

    init(
        enableFirst: Bool,
        enableRepeat: Bool,
        firstTime: Date,
        startTime: Date,
        endTime: Date,
        intervalMinutes: Int,
        now: Date,
        calendar: Calendar = .current
    ) {
        self.enableFirst = enableFirst
        self.enableRepeat = enableRepeat
        self.firstTime = firstTime
        self.startTime = startTime
        self.endTime = endTime
        self.intervalMinutes = intervalMinutes
        self.now = now
        self.calendar = calendar
    }

    /// Returns the active (or next upcoming) window for the current `now`, or `nil` if repeating is disabled.
    func currentWindow() -> (start: Date, end: Date)? {
        guard enableRepeat else { return nil }
        let startToday = todayDate(from: startTime)
        let endToday = todayDate(from: endTime)
        return effectiveWindow(startToday: startToday, endToday: endToday)
    }

    /// Returns the date of the next first-time notification, or `nil` if disabled.
    func nextFirstNotification() -> Date? {
        guard enableFirst else { return nil }
        let firstToday = todayDate(from: firstTime)
        return firstToday < now ? calendar.date(byAdding: .day, value: 1, to: firstToday) : firstToday
    }

    /// Returns a `RepeatInfo` describing the next repeating notification, or `nil` if disabled.
    func nextRepeat() -> RepeatInfo? {
        guard enableRepeat else { return nil }

        let startToday = todayDate(from: startTime)
        let endToday = todayDate(from: endTime)

        let (windowStart, windowEnd) = effectiveWindow(startToday: startToday, endToday: endToday)

        guard let nextTime = computeNextRepeatTime(windowStart: windowStart, windowEnd: windowEnd) else {
            return nil
        }

        return RepeatInfo(
            nextTime: nextTime,
            windowStart: windowStart,
            windowEnd: windowEnd,
            intervalMinutes: intervalMinutes
        )
    }

    // MARK: - Helpers

    private func todayDate(from date: Date) -> Date {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return calendar.date(bySettingHour: comps.hour!, minute: comps.minute!, second: 0, of: now)!
    }

    /// Determines the active (or upcoming) window by checking offsets.
    private func effectiveWindow(startToday: Date, endToday: Date) -> (start: Date, end: Date) {
        // We'll check offsets from -1 to +2 to cover all edge cases.
        let offsets = [-1, 0, 1, 2]

        for offset in offsets {
            let start = calendar.date(byAdding: .day, value: offset, to: startToday)!
            let end: Date
            if startToday <= endToday {
                // Normal window: start and end on the same day
                end = calendar.date(byAdding: .day, value: offset, to: endToday)!
            } else {
                // Crossing window: end is one day after the start's offset
                end = calendar.date(byAdding: .day, value: offset + 1, to: endToday)!
            }

            if now < start {
                // This window starts in the future -> return it
                return (start, end)
            } else if now >= start && now < end {
                // We are inside this window -> return it
                return (start, end)
            }
            // Otherwise, move to the next offset
        }

        // Fallback (should never happen)
        let fallbackStart = calendar.date(byAdding: .day, value: 1, to: startToday)!
        let fallbackEnd = calendar.date(byAdding: .day, value: 1, to: endToday)!
        return (fallbackStart, fallbackEnd)
    }

    private func computeNextRepeatTime(windowStart: Date, windowEnd: Date) -> Date? {
        guard now < windowEnd else {
            // Already past the window - schedule the next start (which will be tomorrow)
            return calendar.date(byAdding: .day, value: 1, to: windowStart)
        }

        if now < windowStart {
            return windowStart
        }

        // Inside the window - calculate the next interval boundary
        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        let elapsed = now.timeIntervalSince(windowStart)
        let intervalsElapsed = Int(elapsed / intervalSeconds)
        let candidate = windowStart.addingTimeInterval(TimeInterval((intervalsElapsed + 1) * intervalMinutes * 60))

        if candidate < windowEnd {
            return candidate
        } else {
            // No more intervals today -> tomorrow's start
            return calendar.date(byAdding: .day, value: 1, to: windowStart)
        }
    }
}

// MARK: - Supporting types

struct RepeatInfo {
    let nextTime: Date
    let windowStart: Date
    let windowEnd: Date
    let intervalMinutes: Int
}