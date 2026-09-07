import Foundation

enum DailyCalendar {
    static let appGroupID = "group.Jason-Wang.CodeBreaker"
    static let completedDatesKey = "daily_completed_dates"

    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 1
        return calendar
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func stableSeed(_ key: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in key.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return hash == 0 ? 1 : hash
    }

    static func isLieDay(_ key: String = dayKey()) -> Bool {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              let date = gregorian.date(from: DateComponents(year: year, month: month, day: day)),
              let dayOfYear = gregorian.ordinality(of: .day, in: .year, for: date)
        else { return false }
        return dayOfYear % 3 == 0
    }

    static func dayNumber(_ date: Date = Date()) -> Int {
        let start = gregorian.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let today = gregorian.startOfDay(for: date)
        return (gregorian.dateComponents([.day], from: start, to: today).day ?? 0) + 1
    }

    static var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func weekdaySymbols(locale: Locale) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.locale = locale
        return formatter.veryShortWeekdaySymbols
    }
}
