import WidgetKit
import SwiftUI

// MARK: - Shared Data Reader

struct DailyWidgetData {
    let dayNumber: Int
    let isCompleted: Bool
    let currentStreak: Int
    let completedDates: Set<String>

    static func load() -> DailyWidgetData {
        let defaults = UserDefaults(suiteName: "group.Jason-Wang.CodeBreaker") ?? .standard
        let completedDates = Set(defaults.stringArray(forKey: "daily_completed_dates") ?? [])

        let cal = Calendar.current
        let ref = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let today = cal.startOfDay(for: Date())
        let dayNumber = (cal.dateComponents([.day], from: ref, to: today).day ?? 0) + 1

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let todayKey = fmt.string(from: Date())
        let isCompleted = completedDates.contains(todayKey)

        var streak = 0
        var date = Date()
        while true {
            let key = fmt.string(from: date)
            if completedDates.contains(key) {
                streak += 1
            } else if streak > 0 {
                break
            } else {
                if cal.isDateInToday(date) {
                    date = cal.date(byAdding: .day, value: -1, to: date)!
                    continue
                }
                break
            }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }

        return DailyWidgetData(
            dayNumber: dayNumber,
            isCompleted: isCompleted,
            currentStreak: streak,
            completedDates: completedDates
        )
    }
}

// MARK: - Timeline

struct DailyEntry: TimelineEntry {
    let date: Date
    let data: DailyWidgetData
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(date: .now, data: DailyWidgetData(dayNumber: 160, isCompleted: false, currentStreak: 5, completedDates: []))
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        completion(DailyEntry(date: .now, data: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        let entry = DailyEntry(date: .now, data: .load())
        let cal = Calendar.current
        let tomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now)!)
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

// MARK: - Widget Entry View

struct CodeBreakerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DailyEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: DailyEntry

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let darkBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(accent)
                Text("Mind Cipher")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("DAY #\(entry.data.dayNumber)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.8))
                .tracking(1)

            Spacer(minLength: 4)

            if entry.data.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(accent)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 32))
                    .foregroundStyle(warning)
            }

            Spacer(minLength: 4)

            if entry.data.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(warning)
                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Text(entry.data.isCompleted ? "Completed" : "Tap to play")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkBg)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: DailyEntry

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let darkBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    private var monthDays: [Date?] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let firstOfMonth = cal.date(from: comps)!
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst - 1)
        for day in 1...daysInMonth {
            var dc = comps
            dc.day = day
            days.append(cal.date(from: dc))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(accent)
                    Text("Mind Cipher")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("#\(entry.data.dayNumber)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(accent.opacity(0.8))

                Spacer(minLength: 2)

                if entry.data.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(accent)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(warning)
                }

                Spacer(minLength: 2)

                if entry.data.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(warning)
                        Text("\(entry.data.currentStreak)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                Text(entry.data.isCompleted ? "Done!" : "Tap to play")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(width: 90)

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                let cols = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
                LazyVGrid(columns: cols, spacing: 1) {
                    ForEach(0..<monthDays.count, id: \.self) { i in
                        if let date = monthDays[i] {
                            miniDayCell(date)
                        } else {
                            Color.clear.frame(width: 12, height: 12)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkBg)
    }

    private func miniDayCell(_ date: Date) -> some View {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let key = fmt.string(from: date)
        let completed = entry.data.completedDates.contains(key)
        let isToday = cal.isDateInToday(date)
        let isFuture = date > Date()

        return RoundedRectangle(cornerRadius: 2)
            .fill(
                completed ? accent :
                isToday ? warning.opacity(0.5) :
                isFuture ? Color.white.opacity(0.05) :
                Color.white.opacity(0.1)
            )
            .frame(width: 12, height: 12)
    }
}

// MARK: - Widget Bundle

@main
struct CodeBreakerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CodeBreakerWidget()
    }
}

struct CodeBreakerWidget: Widget {
    let kind = "CodeBreakerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProvider()) { entry in
            if #available(iOS 17.0, *) {
                CodeBreakerWidgetEntryView(entry: entry)
                    .containerBackground(.clear, for: .widget)
                    .widgetURL(URL(string: "codebreaker://daily"))
            }
        }
        .configurationDisplayName("Daily Challenge")
        .description("Track your daily challenge streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
