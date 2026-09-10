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
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func stableSeed(_ key: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in key.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return hash == 0 ? 1 : hash
    }

    static func isLieDay(_ key: String = dayKey()) -> Bool {
        guard let date = date(from: key),
              let dayOfYear = gregorian.ordinality(of: .day, in: .year, for: date)
        else { return false }
        return dayOfYear % 3 == 0
    }

    /// Board parameters for one day's case. Shared by everyone: derived from the
    /// date alone, so it can be shown before the case starts.
    struct Spec: Equatable {
        let codeLength: Int
        let colorCount: Int
        let allowDuplicates: Bool
        let maxAttempts: Int
        let lieMode: Bool
    }

    /// The week climbs from a 4×6 board on Monday to 5×8 with repeats on Sunday,
    /// so regulars meet every campaign difficulty in a week and newcomers still
    /// get an easy start. Budgets sit inside the campaign range for the same
    /// board (a consistent solver finishes with 3+ to spare; a careless one wins
    /// about half the time on weekends). Lie days (every third day of the year)
    /// add five attempts, matching the Free Play lie margin.
    static func spec(for key: String = dayKey()) -> Spec {
        // (length, colours, repeats, attempts) indexed by Calendar weekday: 1 = Sunday
        let ladder: [Int: (Int, Int, Bool, Int)] = [
            2: (4, 6, false, 8),   // Mon
            3: (4, 7, false, 8),   // Tue
            4: (4, 6, true, 8),    // Wed
            5: (5, 6, false, 9),   // Thu
            6: (4, 8, true, 10),   // Fri
            7: (5, 7, true, 11),   // Sat
            1: (5, 8, true, 12),   // Sun
        ]
        let weekday = date(from: key).map { gregorian.component(.weekday, from: $0) } ?? 2
        let (length, colours, repeats, attempts) = ladder[weekday] ?? (4, 6, false, 8)
        let lie = isLieDay(key)
        return Spec(
            codeLength: length,
            colorCount: colours,
            allowDuplicates: repeats,
            maxAttempts: attempts + (lie ? 5 : 0),
            lieMode: lie
        )
    }

    static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }
        return gregorian.date(from: DateComponents(year: year, month: month, day: day))
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
