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
        completion(DailyEntry(date: .now, data: DailyWidgetData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        let entry = DailyEntry(date: .now, data: DailyWidgetData.load())
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

/// Paper tokens for the widget (the extension does not compile Theme.swift).
enum WidgetPaper {
    static let paper = Color(red: 0.945, green: 0.914, blue: 0.839)
    static let ink = Color(red: 0.169, green: 0.137, blue: 0.094)
    static let inkFaded = Color(red: 0.478, green: 0.431, blue: 0.353)
    static let inkMuted = Color(red: 0.663, green: 0.624, blue: 0.549)
    static let rule = ink.opacity(0.28)
    static let stamp = Color(red: 0.722, green: 0.196, blue: 0.169)

    static func type(_ size: CGFloat, bold: Bool = true) -> Font {
        .custom(bold ? "AmericanTypewriter-Bold" : "AmericanTypewriter", size: size)
    }
}

/// Miniature rubber stamp.
struct WidgetStamp: View {
    let text: String
    var size: CGFloat = 9
    var rotation: Double = -6
    var body: some View {
        Text(text.uppercased())
            .font(WidgetPaper.type(size))
            .tracking(size * 0.15)
            .foregroundStyle(WidgetPaper.stamp)
            .padding(.horizontal, size * 0.5)
            .padding(.vertical, size * 0.25)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(WidgetPaper.stamp, lineWidth: 1.5))
            .opacity(0.88)
            .rotationEffect(.degrees(rotation))
    }
}

struct SmallWidgetView: View {
    let entry: DailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CASE FILE")
                .font(WidgetPaper.type(8))
                .tracking(1.6)
                .foregroundStyle(WidgetPaper.inkFaded)
            Text(String(format: "No. %04d", entry.data.dayNumber))
                .font(WidgetPaper.type(17))
                .foregroundStyle(WidgetPaper.ink)

            Rectangle().fill(WidgetPaper.rule).frame(height: 1).padding(.vertical, 4)

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                if entry.data.isCompleted {
                    WidgetStamp(text: W("widget.solved"), size: 9, rotation: -8)
                } else if entry.data.isLieDay {
                    WidgetStamp(text: "Top Secret", size: 8, rotation: -8)
                } else {
                    Text(W("widget.play"))
                        .font(WidgetPaper.type(10, bold: false))
                        .foregroundStyle(WidgetPaper.inkFaded)
                }
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.data.currentStreak)")
                    .font(WidgetPaper.type(18))
                    .foregroundStyle(WidgetPaper.ink)
                Text(W("widget.streak"))
                    .font(WidgetPaper.type(8, bold: false))
                    .tracking(1)
                    .foregroundStyle(WidgetPaper.inkFaded)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct MediumWidgetView: View {
    let entry: DailyEntry

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
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CASE FILE")
                    .font(WidgetPaper.type(8))
                    .tracking(1.6)
                    .foregroundStyle(WidgetPaper.inkFaded)
                Text(String(format: "No. %04d", entry.data.dayNumber))
                    .font(WidgetPaper.type(16))
                    .foregroundStyle(WidgetPaper.ink)

                Spacer(minLength: 2)

                if entry.data.isCompleted {
                    WidgetStamp(text: W("widget.solved"), size: 8, rotation: -8)
                } else if entry.data.isLieDay {
                    WidgetStamp(text: "Top Secret", size: 7, rotation: -8)
                } else {
                    Text(W("widget.play"))
                        .font(WidgetPaper.type(10, bold: false))
                        .foregroundStyle(WidgetPaper.inkFaded)
                }

                Spacer(minLength: 2)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.data.currentStreak)")
                        .font(WidgetPaper.type(16))
                        .foregroundStyle(WidgetPaper.ink)
                    Text(W("widget.streak"))
                        .font(WidgetPaper.type(8, bold: false))
                        .tracking(1)
                        .foregroundStyle(WidgetPaper.inkFaded)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 96, alignment: .leading)

            Rectangle().fill(WidgetPaper.rule).frame(width: 1)

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    ForEach(Array(DailyCalendar.weekdaySymbols(locale: .current).enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(WidgetPaper.type(7, bold: false))
                            .foregroundStyle(WidgetPaper.inkMuted)
                            .frame(maxWidth: .infinity)
                    }
                }

                let weeks = stride(from: 0, to: monthDays.count, by: 7).map { start in
                    Array(monthDays[start..<min(start + 7, monthDays.count)])
                }
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { column in
                            if column < week.count, let date = week[column] {
                                miniDayCell(date)
                            } else {
                                Color.clear.frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func miniDayCell(_ date: Date) -> some View {
        let calendar = DailyCalendar.gregorian
        let key = DailyCalendar.dayKey(date)
        let completed = entry.data.completedDates.contains(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()

        return ZStack {
            RoundedRectangle(cornerRadius: 1)
                .stroke(isFuture ? WidgetPaper.rule.opacity(0.5) : WidgetPaper.rule, lineWidth: 1)
            if completed {
                Circle()
                    .fill(WidgetPaper.stamp)
                    .frame(width: 7, height: 7)
            } else if isToday {
                Circle()
                    .stroke(WidgetPaper.ink, lineWidth: 1.5)
                    .frame(width: 7, height: 7)
            }
        }
        .frame(width: 12, height: 12)
    }
}

struct CircularLockView: View {
    let entry: DailyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.data.isLieDay ? "theatermasks.fill" : "doc.text.fill")
                    .font(.system(size: 16, weight: .semibold))
                if entry.data.currentStreak > 0 {
                    Text("\(entry.data.currentStreak)")
                        .font(WidgetPaper.type(12))
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
                Image(systemName: entry.data.isLieDay ? "theatermasks.fill" : "doc.text.fill")
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.data.isLieDay ? W("widget.lie") : W("widget.display"))
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.data.isCompleted ? W("widget.completed") : W("widget.play"))
                        .font(.system(size: 11))
                }
                Spacer(minLength: 0)
                if entry.data.currentStreak > 0 {
                    Text("\(entry.data.currentStreak)")
                        .font(WidgetPaper.type(16))
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
                .containerBackground(WidgetPaper.paper, for: .widget)
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
