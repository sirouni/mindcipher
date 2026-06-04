import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var started = false
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var displayDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: "daily_\(dateString)")
    }

    private var currentStreak: Int {
        DailyStreakManager.shared.currentStreak
    }

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            if !started {
                preStartView
            }
        }
        .navigationDestination(isPresented: $started) {
            GameView(viewModel: viewModel)
        }
        .navigationTitle("Daily Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var preStartView: some View {
        ScrollView {
            VStack(spacing: 20) {

                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(currentStreak)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.warning)
                        Text("Day Streak")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    VStack(spacing: 2) {
                        Text("\(DailyStreakManager.shared.totalCompleted)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                        Text("Total")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.top, 12)

                DailyCalendarView()
                    .padding(.horizontal, 4)

                Text(displayDate)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: 8) {
                    ruleRow("Code length", "4")
                    ruleRow("Colors", "6")
                    ruleRow("Max attempts", "7")
                    ruleRow("Allow repeats", "No")
                }
                .padding(16)
                .glassCard(cornerRadius: 14)

                if isCompleted {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.accent)
                        Text("Today's challenge complete")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                        Text("Come back tomorrow!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if !isCompleted {
                    Button {
                        startDailyChallenge()
                    } label: {
                        Text("Start")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.warning, in: RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button { dismiss() } label: {
                        Text("Back to Home")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .glassCard(cornerRadius: 14)
                    }
                }
            }
            .padding(24)
        }
    }

    private func ruleRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func startDailyChallenge() {
        let seed = dateString.hashValue
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))

        let colors = Array(PegColor.allCases.prefix(6))
        var pool = colors
        var code: [PegColor] = []
        for _ in 0..<4 {
            let idx = Int(rng.next() % UInt64(pool.count))
            code.append(pool.remove(at: idx))
        }

        viewModel.startDuel(secretCode: code, colorCount: 6, maxAttempts: 7)
        viewModel.mode = .freePlay
        UserDefaults.standard.set(true, forKey: "ach_daily_active")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UserDefaults.standard.set(true, forKey: "daily_\(dateString)")
            DailyStreakManager.shared.markCompleted(date: dateString)
        }

        started = true
    }
}

// MARK: - Daily Streak Manager

class DailyStreakManager {
    static let shared = DailyStreakManager()
    private let completedDatesKey = "daily_completed_dates"

    var completedDates: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: completedDatesKey) ?? [])
    }

    var totalCompleted: Int { completedDates.count }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var date = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        while true {
            let key = fmt.string(from: date)
            if completedDates.contains(key) {
                streak += 1
            } else if streak > 0 {
                break
            } else {
                // Today not done yet, check yesterday
                if date == cal.startOfDay(for: Date()) {
                    date = cal.date(byAdding: .day, value: -1, to: date)!
                    continue
                }
                break
            }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    func markCompleted(date: String) {
        var dates = UserDefaults.standard.stringArray(forKey: completedDatesKey) ?? []
        if !dates.contains(date) {
            dates.append(date)
            UserDefaults.standard.set(dates, forKey: completedDatesKey)
        }
    }

    func isCompleted(_ date: String) -> Bool {
        completedDates.contains(date)
    }
}

// MARK: - Calendar View

struct DailyCalendarView: View {
    private let calendar = Calendar.current
    private let today = Date()
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var monthDays: [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: today)
        let firstOfMonth = calendar.date(from: comps)!
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst - 1)
        for day in 1...daysInMonth {
            var dc = comps
            dc.day = day
            days.append(calendar.date(from: dc))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: today)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(monthTitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<monthDays.count, id: \.self) { i in
                    if let date = monthDays[i] {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    private func dayCell(_ date: Date) -> some View {
        let key = formatter.string(from: date)
        let completed = DailyStreakManager.shared.isCompleted(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > today
        let dayNum = calendar.component(.day, from: date)

        return ZStack {
            if completed {
                Circle()
                    .fill(AppTheme.accent.opacity(0.85))
                    .frame(width: 30, height: 30)
            } else if isToday {
                Circle()
                    .stroke(AppTheme.warning, lineWidth: 2)
                    .frame(width: 30, height: 30)
            }

            Text("\(dayNum)")
                .font(.system(size: 12, weight: completed ? .bold : .medium, design: .rounded))
                .foregroundStyle(
                    completed ? .white :
                    isToday ? AppTheme.warning :
                    isFuture ? AppTheme.textMuted.opacity(0.4) :
                    AppTheme.textSecondary
                )
        }
        .frame(height: 32)
    }
}

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
