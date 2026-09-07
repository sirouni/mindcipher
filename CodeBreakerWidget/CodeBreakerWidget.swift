import SwiftUI
import WidgetKit

struct DailyWidgetData {
    let dayNumber: Int
    let isCompleted: Bool
    let isLieDay: Bool
    let currentStreak: Int
    let completedDates: Set<String>

    static func load() -> DailyWidgetData {
        let defaults = DailyCalendar.appGroupDefaults
        let completedDates = Set(defaults.stringArray(forKey: DailyCalendar.completedDatesKey) ?? [])
        let todayKey = DailyCalendar.dayKey()
        let calendar = DailyCalendar.gregorian

        var streak = 0
        var date = Date()
        while true {
            let key = DailyCalendar.dayKey(date)
            if completedDates.contains(key) {
                streak += 1
            } else if streak > 0 {
                break
            } else if calendar.isDateInToday(date) {
                date = calendar.date(byAdding: .day, value: -1, to: date)!
                continue
            } else {
                break
            }
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }

        return DailyWidgetData(
            dayNumber: DailyCalendar.dayNumber(),
            isCompleted: completedDates.contains(todayKey),
            isLieDay: DailyCalendar.isLieDay(todayKey),
            currentStreak: streak,
            completedDates: completedDates
        )
    }
}

struct DailyEntry: TimelineEntry {
    let date: Date
    let data: DailyWidgetData
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(
            date: .now,
            data: DailyWidgetData(dayNumber: 160, isCompleted: false, isLieDay: true, currentStreak: 5, completedDates: [])
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        completion(DailyEntry(date: .now, data: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        let entry = DailyEntry(date: .now, data: .load())
        let calendar = DailyCalendar.gregorian
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

struct CodeBreakerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DailyEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularLockView(entry: entry)
        case .accessoryRectangular:
            RectangularLockView(entry: entry)
        case .accessoryInline:
            Text(entry.data.isLieDay ? W("widget.lie") : W("widget.display"))
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: DailyEntry

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let danger = Color(red: 0.85, green: 0.25, blue: 0.25)
    private let darkBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: entry.data.isLieDay ? "theatermask.and.paintbrush.fill" : "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(entry.data.isLieDay ? danger : accent)
                Text("Mind Cipher")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(entry.data.isLieDay ? W("widget.lie") : W("widget.day", entry.data.dayNumber))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle((entry.data.isLieDay ? danger : accent).opacity(0.85))
                .tracking(0.6)

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

            Text(entry.data.isCompleted ? W("widget.completed") : W("widget.play"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkBg)
    }
}

struct MediumWidgetView: View {
    let entry: DailyEntry

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let danger = Color(red: 0.85, green: 0.25, blue: 0.25)
    private let darkBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    private var monthDays: [Date?] {
        let calendar = DailyCalendar.gregorian
        let comps = calendar.dateComponents([.year, .month], from: Date())
        let firstOfMonth = calendar.date(from: comps)!
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst - 1)
        for day in 1...daysInMonth {
            var components = comps
            components.day = day
            days.append(calendar.date(from: components))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: entry.data.isLieDay ? "theatermask.and.paintbrush.fill" : "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(entry.data.isLieDay ? danger : accent)
                    Text("Mind Cipher")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(entry.data.isLieDay ? W("widget.lie") : "#\(entry.data.dayNumber)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle((entry.data.isLieDay ? danger : accent).opacity(0.85))

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

                Text(entry.data.isCompleted ? W("widget.done") : W("widget.play"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(width: 90)

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    ForEach(Array(DailyCalendar.weekdaySymbols(locale: .current).enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(0..<monthDays.count, id: \.self) { index in
                        if let date = monthDays[index] {
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
        let calendar = DailyCalendar.gregorian
        let key = DailyCalendar.dayKey(date)
        let completed = entry.data.completedDates.contains(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let isLie = DailyCalendar.isLieDay(key)

        return RoundedRectangle(cornerRadius: 2)
            .fill(
                completed ? (isLie ? danger : accent) :
                isToday ? warning.opacity(0.5) :
                isFuture ? Color.white.opacity(0.05) :
                Color.white.opacity(0.1)
            )
            .frame(width: 12, height: 12)
    }
}

struct CircularLockView: View {
    let entry: DailyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.data.isLieDay ? "theatermask.and.paintbrush.fill" : "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                if entry.data.currentStreak > 0 {
                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
            }
        }
    }
}

struct RectangularLockView: View {
    let entry: DailyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            HStack(spacing: 8) {
                Image(systemName: entry.data.isLieDay ? "theatermask.and.paintbrush.fill" : "lock.shield.fill")
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.data.isLieDay ? W("widget.lie") : W("widget.display"))
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.data.isCompleted ? W("widget.completed") : W("widget.play"))
                        .font(.system(size: 11))
                }
                Spacer(minLength: 0)
                if entry.data.currentStreak > 0 {
                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

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
            CodeBreakerWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "codebreaker://daily"))
        }
        .configurationDisplayName(W("widget.display"))
        .description(W("widget.desc"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
