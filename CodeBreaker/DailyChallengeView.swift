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
    private var spec: DailyCalendar.Spec { DailyCalendar.spec(for: dateString) }
    private var isLieDaily: Bool { spec.lieMode }

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
            VStack(alignment: .leading, spacing: 18) {
                // Case header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        DossierCaption(text: L("home.today"), color: isLieDaily ? AppTheme.danger : AppTheme.textSecondary)
                        Text(L("case.no", DailyCalendar.dayNumber()))
                            .font(AppFont.display(26, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(displayDate)
                            .font(AppFont.label(11, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if isCompleted {
                        StampView(text: L("case.closed"), tone: .red, size: 12, rotation: -10)
                            .padding(.top, 6)
                    } else if isLieDaily {
                        StampView(text: "Top Secret", tone: .red, size: 12, rotation: -10)
                            .padding(.top, 6)
                            .accessibilityIdentifier("daily.lie.badge")
                    }
                }
                Rectangle().fill(AppTheme.ink).frame(height: 1.5)

                // Attendance ledger
                HStack(spacing: 0) {
                    ledgerStat(value: currentStreak, label: L("daily.attendance"))
                    Rectangle().fill(AppTheme.rule).frame(width: 1, height: 30)
                    ledgerStat(value: DailyStreakManager.shared.totalCompleted, label: L("daily.total"))
                    if gcManager.isAuthenticated {
                        Rectangle().fill(AppTheme.rule).frame(width: 1, height: 30)
                        Button { showLeaderboard = true } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "list.number")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(L("daily.leaderboard").uppercased())
                                    .font(AppFont.label(8, weight: .regular))
                                    .tracking(0.8)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: $showLeaderboard) {
                            GameCenterLeaderboardView()
                        }
                    }
                }
                .padding(.vertical, 10)
                .paperCard()

                DailyCalendarView()

                if isLieDaily {
                    Text(L("daily.lie.rule"))
                        .font(AppFont.body(13))
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(AppTheme.danger, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                }

                VStack(spacing: 0) {
                    ruleRow(L("param.length"), "\(spec.codeLength)")
                    ruleRow(L("param.colors"), "\(spec.colorCount)")
                    ruleRow(L("param.attempts"), "\(spec.maxAttempts)")
                    ruleRow(L("param.repeat"), spec.allowDuplicates ? L("param.yes") : L("param.no"), last: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .paperCard()

                if isCompleted {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("daily.completed"))
                            .font(AppFont.display(15, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(L("daily.tomorrow"))
                            .font(AppFont.body(12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !isCompleted {
                    Button { startDailyChallenge() } label: { Text(L("daily.start")) }
                        .buttonStyle(InkButtonStyle())
                } else {
                    Button { dismiss() } label: { Text(L("daily.back")) }
                        .buttonStyle(InkButtonStyle(prominent: false))
                }
            }
            .padding(20)
        }
    }

    private func ledgerStat(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppFont.display(20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label.uppercased())
                .font(AppFont.label(8, weight: .regular))
                .tracking(0.8)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func ruleRow(_ label: String, _ value: String, last: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.mono(13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { if !last { TypewriterRule() } }
    }

    private func startDailyChallenge() {
        let seed = DailyCalendar.stableSeed(dateString)
        viewModel.startChallenge(
            seed: seed,
            codeLength: spec.codeLength,
            colorCount: spec.colorCount,
            allowDuplicates: spec.allowDuplicates,
            maxAttempts: spec.maxAttempts,
            lieMode: spec.lieMode
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
            HStack {
                DossierCaption(text: monthTitle, color: AppTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Circle().stroke(AppTheme.accent, lineWidth: 1.5).frame(width: 10, height: 10)
                    Text(L("case.closed"))
                        .font(AppFont.label(9, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(DailyCalendar.weekdaySymbols(locale: LanguageManager.shared.locale).enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(AppFont.label(9, weight: .regular))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid: every day is a box; done days get a red stamp ring
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<monthDays.count, id: \.self) { i in
                    if let date = monthDays[i] {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 34)
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

        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(isToday ? AppTheme.ink : AppTheme.rule, lineWidth: isToday ? 1.5 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isLie && !isFuture ? AppTheme.danger.opacity(0.07) : .clear)
                )

            Text("\(dayNum)")
                .font(AppFont.label(11, weight: isToday ? .bold : .regular))
                .foregroundStyle(
                    isFuture ? AppTheme.textMuted.opacity(0.5) :
                    isToday ? AppTheme.textPrimary : AppTheme.textSecondary
                )

            if completed {
                Circle()
                    .stroke(AppTheme.accent, lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-8))
                    .opacity(0.9)
            }
        }
        .frame(height: 34)
        .accessibilityLabel("\(dayNum)\(completed ? ", \(L("case.closed"))" : "")")
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

