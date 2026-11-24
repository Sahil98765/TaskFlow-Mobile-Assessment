import Foundation

enum DueDate {
    static func isValid(_ value: String) -> Bool {
        guard let match = value.wholeMatch(of: /(\d{4})-(\d{2})-(\d{2})/),
              let year = Int(match.1),
              let month = Int(match.2),
              let day = Int(match.3)
        else {
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let components = DateComponents(year: year, month: month, day: day)
        return components.isValidDate(in: calendar)
    }
}
