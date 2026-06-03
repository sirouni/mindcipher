import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "settings_sound") }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "settings_haptics") }
    }
    @Published var colorBlindMode: Bool {
        didSet { UserDefaults.standard.set(colorBlindMode, forKey: "settings_colorBlind") }
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "settings_sound") == nil { defaults.set(true, forKey: "settings_sound") }
        if defaults.object(forKey: "settings_haptics") == nil { defaults.set(true, forKey: "settings_haptics") }
        soundEnabled = defaults.bool(forKey: "settings_sound")
        hapticsEnabled = defaults.bool(forKey: "settings_haptics")
        colorBlindMode = defaults.bool(forKey: "settings_colorBlind")
    }
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var stats = StatsManager.shared
    @ObservedObject var progress = ProgressManager.shared
    @State private var showResetAlert = false
    @State private var showResetStatsAlert = false

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    gameSection
                    themeSection
                    statsSection
                    dangerSection
                    aboutSection
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Game")
            VStack(spacing: 0) {
                toggleRow(icon: "speaker.wave.2.fill", title: "Sound", isOn: $settings.soundEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", isOn: $settings.hapticsEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "eye.trianglebadge.exclamationmark", title: "Colorblind", isOn: $settings.colorBlindMode)
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var themeSection: some View {
        ThemePickerView()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Stats")
            VStack(spacing: 0) {
                infoRow(icon: "gamecontroller.fill", title: "Games", value: "\(stats.gamesPlayed)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "trophy.fill", title: "Wins", value: "\(stats.gamesWon)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "percent", title: "Win%", value: stats.gamesPlayed > 0 ? "\(Int(stats.winRate))%" : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "flame.fill", title: "Best streak", value: "\(stats.bestStreak)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "number", title: "Avg steps", value: stats.gamesWon > 0 ? String(format: "%.1f", stats.avgAttempts) : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "star.fill", title: "Stars", value: "\(progress.totalStars)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "checkmark.circle.fill", title: "Levels done", value: "\(progress.completedLevels.count)/240")
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Manage")
            VStack(spacing: 0) {
                Button {
                    showResetStatsAlert = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.warning)
                            .frame(width: 28)
                        Text("Reset Stats")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.warning)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert("Reset stats?", isPresented: $showResetStatsAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                    }
                } message: { Text("Win rate, streaks, etc. will be cleared") }

                Divider().overlay(AppTheme.textMuted.opacity(0.2))

                Button {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.danger)
                            .frame(width: 28)
                        Text("Reset All Progress")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.danger)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert("Reset all progress?", isPresented: $showResetAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        progress.completedLevels = []
                        progress.starsByLevel = [:]
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                        UserDefaults.standard.set(false, forKey: "tutorialSeen")
                    }
                } message: { Text("Levels, stars, and stats will be permanently cleared") }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("About")
            VStack(spacing: 0) {
                infoRow(icon: "info.circle.fill", title: "Version", value: "1.0.0")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "lock.shield.fill", title: "Code Breaker", value: "Code Breaker")
            }
            .glassCard(cornerRadius: 14)
        }
    }

    // MARK: - Row Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.accent)
                .labelsHidden()
        }
        .padding(14)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
    }

}

struct AchievementsView: View {
    @ObservedObject var manager = AchievementManager.shared

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 6) {
                    progressHeader

                    ForEach(AchievementCategory.allCases, id: \.rawValue) { cat in
                        let items = AchievementManager.all.filter { $0.category == cat }
                        if !items.isEmpty {
                            categorySection(cat, items: items)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear { manager.checkAll() }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("\(manager.unlockedCount)/\(manager.totalCount)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.accent)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.accent)
                        .frame(width: geo.size.width * CGFloat(manager.unlockedCount) / CGFloat(max(1, manager.totalCount)), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)

            Text("Unlocked")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private func categorySection(_ cat: AchievementCategory, items: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cat.rawValue.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 4)
                .padding(.top, 10)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, a in
                    let unlocked = manager.unlockedIds.contains(a.id)
                    achievementRow(a, unlocked: unlocked)
                    if idx < items.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private func achievementRow(_ a: Achievement, unlocked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppTheme.warning.opacity(0.15) : Color.black.opacity(0.04))
                    .frame(width: 42, height: 42)
                Image(systemName: a.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(unlocked ? AppTheme.warning : AppTheme.textMuted)
                    .opacity(unlocked ? 1 : 0.3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(a.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                Text(a.desc)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 18))
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(AppTheme.textMuted.opacity(0.5))
                    .font(.system(size: 13))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
