import Foundation
import Testing
@testable import TaskFlow

struct CalendarDayTests {
    @Test func parsesValidISODate() throws {
        let day = try #require(CalendarDay(isoString: "2026-10-15"))
        #expect(day.year == 2026)
        #expect(day.month == 10)
        #expect(day.day == 15)
        #expect(day.isoString == "2026-10-15")
    }

    @Test(arguments: ["", "2026-10", "15-10-2026", "2026-02-30", "2026-13-01", "2026-10-15T00:00:00Z", "abcd-ef-gh"])
    func rejectsInvalidStrings(_ value: String) {
        #expect(CalendarDay(isoString: value) == nil)
    }

    @Test func usesTheLocalCalendarDayInsteadOfUTC() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Kolkata"))
        let utcEvening = try #require(ISO8601DateFormatter().date(from: "2026-10-14T20:00:00Z"))

        let day = CalendarDay(date: utcEvening, calendar: calendar)

        #expect(day.isoString == "2026-10-15")
    }

    @Test func comparesChronologically() throws {
        let earlier = try #require(CalendarDay(isoString: "2026-09-30"))
        let later = try #require(CalendarDay(isoString: "2026-10-01"))
        #expect(earlier < later)
    }
}
