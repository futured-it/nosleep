import Foundation
import Testing
@testable import nosleep

@Suite struct ScheduleCalculatorTests {
    var calendar: Calendar
    let referenceDate: Date

    init() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = DateComponents(year: 2026, month: 7, day: 8, hour: 12, minute: 0, second: 0)
        referenceDate = calendar.date(from: comps)!
    }

    func makeTime(hour: Int, minute: Int) -> Date {
        let comps = DateComponents(year: 2026, month: 7, day: 8, hour: hour, minute: minute, second: 0)
        return calendar.date(from: comps)!
    }

    // MARK: - First notification tests
    
    // So that we won't get unexpected notification if it's disabled
    @Test func firstNotificationDisabled() throws {
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: false,
            firstTime: makeTime(hour: 23, minute: 0),
            startTime: makeTime(hour: 23, minute: 30),
            endTime: makeTime(hour: 4, minute: 0),
            intervalMinutes: 10,
            now: referenceDate,
            calendar: calendar
        )
        #expect(calc.nextFirstNotification() == nil)
    }

    // To make sure it correctly schedules the next notification for tomorrow
    // if the first notification time has already passed today
    @Test func firstNotificationTodayBeforeNow() throws {
        let calc = ScheduleCalculator(
            enableFirst: true,
            enableRepeat: false,
            firstTime: makeTime(hour: 10, minute: 0),
            startTime: makeTime(hour: 23, minute: 30),
            endTime: makeTime(hour: 4, minute: 0),
            intervalMinutes: 10,
            now: referenceDate,
            calendar: calendar
        )
        let expected = calendar.date(byAdding: .day, value: 1, to: makeTime(hour: 10, minute: 0))!
        #expect(calc.nextFirstNotification() == expected)
    }

    // To make sure it correctly schedules the next notification for today
    // if the first notification time is still in the future
    @Test func firstNotificationTodayAfterNow() throws {
        let calc = ScheduleCalculator(
            enableFirst: true,
            enableRepeat: false,
            firstTime: makeTime(hour: 14, minute: 0),
            startTime: makeTime(hour: 23, minute: 30),
            endTime: makeTime(hour: 4, minute: 0),
            intervalMinutes: 10,
            now: referenceDate,
            calendar: calendar
        )
        let expected = makeTime(hour: 14, minute: 0)
        #expect(calc.nextFirstNotification() == expected)
    }

    // MARK: - Repeating notification tests

    // Non‑crossing window: 10:00 - 14:00

    // The next notification should be the first one in the window
    // if now is before the window
    @Test func repeatNonCrossingBeforeWindow() throws {
        let start = makeTime(hour: 10, minute: 0)
        let end = makeTime(hour: 14, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 30,
            now: makeTime(hour: 9, minute: 0),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        #expect(info.nextTime == start)
        #expect(info.windowStart == start)
        #expect(info.windowEnd == end)
    }

    // The next notification should be
    // the first one after now in the window
    @Test func repeatNonCrossingInsideWindow() throws {
        let start = makeTime(hour: 10, minute: 0)
        let end = makeTime(hour: 14, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 30,
            now: makeTime(hour: 11, minute: 15),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        let expected = makeTime(hour: 11, minute: 30)
        #expect(info.nextTime == expected)
        #expect(info.windowStart == start)
        #expect(info.windowEnd == end)
    }

    // The next notification should be the first one in the window tomorrow
    @Test func repeatNonCrossingAfterWindow() throws {
        let start = makeTime(hour: 10, minute: 0)
        let end = makeTime(hour: 14, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 30,
            now: makeTime(hour: 15, minute: 0),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        let expectedTomorrow = calendar.date(byAdding: .day, value: 1, to: start)!
        #expect(info.nextTime == expectedTomorrow)
        #expect(info.windowStart == expectedTomorrow)
        #expect(info.windowEnd == calendar.date(byAdding: .day, value: 1, to: end)!)
    }

    // Crossing window: 23:00 - 02:00
    // So that we can test the behavior when the window crosses midnight

    // The next notification should be the first one in the window
    // if now is before the window
    @Test func repeatCrossingBeforeWindow() throws {
        let start = makeTime(hour: 23, minute: 0)
        let end = makeTime(hour: 2, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 15,
            now: makeTime(hour: 22, minute: 0),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        #expect(info.nextTime == start)
        let endTomorrow = calendar.date(byAdding: .day, value: 1, to: end)!
        #expect(info.windowStart == start)
        #expect(info.windowEnd == endTomorrow)
    }

    // Same thing, but now is inside the window (after midnight)
    @Test func repeatCrossingInsideWindow() throws {
        let start = makeTime(hour: 23, minute: 0)
        let end = makeTime(hour: 2, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 15,
            now: makeTime(hour: 0, minute: 30),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        let expected = makeTime(hour: 0, minute: 45)
        #expect(info.nextTime == expected)
        // Active window is yesterday's start to today's end
        let startYesterday = calendar.date(byAdding: .day, value: -1, to: start)!
        let endToday = end // end on the same day as now (July 8)
        #expect(info.windowStart == startYesterday)
        #expect(info.windowEnd == endToday)
    }

    // Same thing, but now is after the window (after midnight)
    @Test func repeatCrossingAfterWindow() throws {
        let start = makeTime(hour: 23, minute: 0)
        let end = makeTime(hour: 2, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 15,
            now: makeTime(hour: 3, minute: 0),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        // Next window is today's start (23:00) to tomorrow's end (02:00)
        #expect(info.nextTime == start) // 23:00 today
        #expect(info.windowStart == start) // 23:00 today
        #expect(info.windowEnd == calendar.date(byAdding: .day, value: 1, to: end)!) // 02:00 tomorrow
    }

    // Edge cases

    // If now is exactly at the end of the window,
    // the next notification should be tomorrow's start
    @Test func repeatWhenNowEqualsRepeatTime() throws {
        let start = makeTime(hour: 10, minute: 0)
        let end = makeTime(hour: 14, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 30,
            now: makeTime(hour: 10, minute: 30),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        let expected = makeTime(hour: 11, minute: 0)
        #expect(info.nextTime == expected)
        #expect(info.windowStart == start)
        #expect(info.windowEnd == end)
    }

    // The next notification should be the first one in the window tomorrow
    // if now is exactly at the end of the window
    @Test func repeatWhenNowExactlyWindowEnd() throws {
        let start = makeTime(hour: 10, minute: 0)
        let end = makeTime(hour: 14, minute: 0)
        let calc = ScheduleCalculator(
            enableFirst: false,
            enableRepeat: true,
            firstTime: makeTime(hour: 0, minute: 0),
            startTime: start,
            endTime: end,
            intervalMinutes: 30,
            now: makeTime(hour: 14, minute: 0),
            calendar: calendar
        )
        let info = try #require(calc.nextRepeat())
        let expectedTomorrow = calendar.date(byAdding: .day, value: 1, to: start)!
        #expect(info.nextTime == expectedTomorrow)
        #expect(info.windowStart == expectedTomorrow)
        #expect(info.windowEnd == calendar.date(byAdding: .day, value: 1, to: end)!)
    }
}