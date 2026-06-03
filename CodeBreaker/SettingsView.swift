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
                infoRow(icon: "checkmark.circle.fill", title: "Levels done", value: "\(progress.completedLevels.count)/120")
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Achievements")
            VStack(spacing: 0) {
                iconAchievementRow("lock.open.fill", "First Crack", "Complete your first game", unlocked: stats.gamesWon >= 1)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("flame.fill", "Streak Master", "Win 5 in a row", unlocked: stats.bestStreak >= 5)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("star.fill", "3-Star Agent", "Get 3 stars on any level", unlocked: progress.starsByLevel.values.contains(3))
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("scope", "Sharpshooter", "Win 10 in a row", unlocked: stats.bestStreak >= 10)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("trophy.fill", "Junior Graduate", "Complete all Junior Agent levels", unlocked: (1...20).allSatisfy { progress.completedLevels.contains($0) })
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("diamond.fill", "Star Master", "Earn 100 stars", unlocked: progress.totalStars >= 100)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                iconAchievementRow("brain.head.profile", "Grandmaster", "Complete all 120 levels", unlocked: progress.completedLevels.count >= 120)
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

    private func iconAchievementRow(_ systemName: String, _ title: String, _ desc: String, unlocked: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 22))
                .foregroundStyle(unlocked ? AppTheme.warning : AppTheme.textMuted)
                .opacity(unlocked ? 1 : 0.3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                Text(desc)
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
                    .foregroundStyle(AppTheme.textMuted)
                    .font(.system(size: 14))
            }
        }
        .padding(14)
    }
}

struct AchievementsView: View {
    @ObservedObject var stats = StatsManager.shared
    @ObservedObject var progress = ProgressManager.shared

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    achievementCard("lock.open.fill", "First Crack", "Complete your first game", unlocked: stats.gamesWon >= 1)
                    achievementCard("flame.fill", "Streak Master", "Win 5 in a row", unlocked: stats.bestStreak >= 5)
                    achievementCard("star.fill", "3-Star Agent", "Get 3 stars on any level", unlocked: progress.starsByLevel.values.contains(3))
                    achievementCard("scope", "Sharpshooter", "Win 10 in a row", unlocked: stats.bestStreak >= 10)
                    achievementCard("trophy.fill", "Junior Graduate", "Complete all Junior Agent levels", unlocked: (1...20).allSatisfy { progress.completedLevels.contains($0) })
                    achievementCard("diamond.fill", "Star Master", "Earn 100 stars", unlocked: progress.totalStars >= 100)
                    achievementCard("brain.head.profile", "Grandmaster", "Complete all 120 levels", unlocked: progress.completedLevels.count >= 120)
                }
                .padding(20)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func achievementCard(_ icon: String, _ title: String, _ desc: String, unlocked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppTheme.warning.opacity(0.15) : Color.black.opacity(0.04))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(unlocked ? AppTheme.warning : AppTheme.textMuted)
                    .opacity(unlocked ? 1 : 0.3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                Text(desc)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 22))
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(AppTheme.textMuted)
                    .font(.system(size: 16))
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
}
