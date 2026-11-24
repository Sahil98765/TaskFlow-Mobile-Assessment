import Foundation

struct CalendarDay: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    private static let validationCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    init?(isoString: String) {
        guard let match = isoString.wholeMatch(of: /(\d{4})-(\d{2})-(\d{2})/),
              let year = Int(match.1),
              let month = Int(match.2),
              let day = Int(match.3),
              DateComponents(year: year, month: month, day: day).isValidDate(in: Self.validationCalendar)
        else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 0
        self.month = components.month ?? 0
        self.day = components.day ?? 0
    }

    static func today(calendar: Calendar = .current) -> CalendarDay {
        CalendarDay(date: .now, calendar: calendar)
    }

    var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    func date(in calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
