import SwiftUI
import GameKit
import WidgetKit

struct DailyChallengeView: View {
    @StateObject private var viewModel = GameViewModel()
    @ObservedObject private var gcManager = GameCenterManager.shared
    @State private var started = false
    @State private var showLeaderboard = false
    @Environment(\.dismiss) private var dismiss

    private var dateString: String { DailyCalendar.dayKey() }
    private var isLieDaily: Bool { DailyCalendar.isLieDay(dateString) }

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.calendar = DailyCalendar.gregorian
        formatter.locale = LanguageManager.shared.locale
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    private var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: "daily_\(dateString)")
    }

    private var currentStreak: Int {
        DailyStreakManager.shared.currentStreak
    }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            if !started {
                preStartView
            }
        }
        .navigationDestination(isPresented: $started) {
            GameView(viewModel: viewModel)
        }
        .navigationTitle(L("daily.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
    }

    private var preStartView: some View {
        ScrollView {
            VStack(spacing: 20) {

                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(currentStreak)")
                            .font(AppFont.display(28, weight: .black))
                            .foregroundStyle(AppTheme.warning)
                        Text(L("daily.streak"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    VStack(spacing: 2) {
                        Text("\(DailyStreakManager.shared.totalCompleted)")
                            .font(AppFont.display(28, weight: .black))
                            .foregroundStyle(AppTheme.accent)
                        Text(L("daily.total"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.top, 12)

                DailyCalendarView()
                    .padding(.horizontal, 4)

                if gcManager.isAuthenticated {
                    Button {
                        showLeaderboard = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 14))
                            Text(L("daily.leaderboard"))
                                .font(AppFont.display(14, weight: .bold))
                        }
                        .foregroundStyle(AppTheme.warning)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .paperCard()
                    }
                    .sheet(isPresented: $showLeaderboard) {
                        GameCenterLeaderboardView()
                    }
                }

                Text(displayDate)
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if isLieDaily {
                    HStack(spacing: 6) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                        Text(L("daily.lie.badge"))
                    }
                    .font(AppFont.display(13, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.danger.opacity(0.12), in: Capsule())
                    .accessibilityIdentifier("daily.lie.badge")
                }

                VStack(spacing: 8) {
                    ruleRow(L("param.length"), "4")
                    ruleRow(L("param.colors"), "6")
                    ruleRow(L("param.attempts"), isLieDaily ? "8" : "7")
                    ruleRow(L("param.repeat"), L("param.no"))
                    if isLieDaily {
                        ruleRow(L("lie.toggle"), L("daily.lie.rule"))
                    }
                }
                .padding(16)
                .paperCard()

                if isCompleted {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.accent)
                        Text(L("daily.completed"))
                            .font(AppFont.display(15, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text(L("daily.tomorrow"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if !isCompleted {
                    Button {
                        startDailyChallenge()
                    } label: {
                        Text(L("daily.start"))
                            .font(AppFont.display(18, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.warning, in: RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button { dismiss() } label: {
                        Text(L("daily.back"))
                            .font(AppFont.display(16, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .paperCard()
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
        let seed = DailyCalendar.stableSeed(dateString)
        viewModel.startChallenge(
            seed: seed,
            codeLength: 4,
            colorCount: 6,
            allowDuplicates: false,
            maxAttempts: isLieDaily ? 8 : 7,
            lieMode: isLieDaily
        )
        viewModel.mode = .freePlay
        viewModel.isDailyChallenge = true
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
    private let completedDatesKey = DailyCalendar.completedDatesKey

    var completedDates: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: completedDatesKey) ?? [])
    }

    var totalCompleted: Int { completedDates.count }

    var currentStreak: Int {
        let cal = DailyCalendar.gregorian
        var streak = 0
        var date = Date()

        while true {
            let key = DailyCalendar.dayKey(date)
            if completedDates.contains(key) {
                streak += 1
            } else if streak > 0 {
                break
            } else {
                // Today not done yet, check yesterday
                if cal.isDateInToday(date) {
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
        syncToAppGroup()
        WidgetCenter.shared.reloadTimelines(ofKind: "CodeBreakerWidget")
    }

    func syncToAppGroup() {
        let dates = UserDefaults.standard.stringArray(forKey: completedDatesKey) ?? []
        DailyCalendar.appGroupDefaults.set(dates, forKey: completedDatesKey)
        DailyCalendar.appGroupDefaults.set(DailyCalendar.isLieDay(), forKey: "daily_is_lie_today")
    }

    func isCompleted(_ date: String) -> Bool {
        completedDates.contains(date)
    }
}

// MARK: - Calendar View

struct DailyCalendarView: View {
    private let calendar = DailyCalendar.gregorian
    private let today = Date()

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
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = LanguageManager.shared.locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: today)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(monthTitle)
                .font(AppFont.display(14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(DailyCalendar.weekdaySymbols(locale: LanguageManager.shared.locale).enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
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
        .paperCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let key = DailyCalendar.dayKey(date)
        let completed = DailyStreakManager.shared.isCompleted(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > today
        let isLie = DailyCalendar.isLieDay(key)
        let dayNum = calendar.component(.day, from: date)
        let todayColor = isLie ? AppTheme.danger : AppTheme.warning

        return ZStack {
            if completed {
                Circle()
                    .fill((isLie ? AppTheme.danger : AppTheme.accent).opacity(0.85))
                    .frame(width: 30, height: 30)
            } else if isToday {
                Circle()
                    .stroke(todayColor, lineWidth: 2)
                    .frame(width: 30, height: 30)
            } else if isLie && !isFuture {
                Circle()
                    .stroke(AppTheme.danger.opacity(0.35), lineWidth: 1)
                    .frame(width: 30, height: 30)
            }

            Text("\(dayNum)")
                .font(AppFont.display(12, weight: completed ? .bold : .medium))
                .foregroundStyle(
                    completed ? .white :
                    isToday ? todayColor :
                    isFuture ? AppTheme.textMuted.opacity(0.4) :
                    AppTheme.textSecondary
                )
        }
        .frame(height: 32)
    }
}

// MARK: - Game Center Leaderboard View

struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    let leaderboardID: String
    let timeScope: GKLeaderboard.TimeScope

    init(leaderboardID: String = GameCenterManager.totalLeaderboardID,
         timeScope: GKLeaderboard.TimeScope = .allTime) {
        self.leaderboardID = leaderboardID
        self.timeScope = timeScope
    }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: timeScope
        )
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

