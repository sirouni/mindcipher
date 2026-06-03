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
                    achievementsSection
                    dangerSection
                    aboutSection
                }
                .padding(20)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("游戏")
            VStack(spacing: 0) {
                toggleRow(icon: "speaker.wave.2.fill", title: "音效", isOn: $settings.soundEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "iphone.radiowaves.left.and.right", title: "触觉反馈", isOn: $settings.hapticsEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "eye.trianglebadge.exclamationmark", title: "色盲辅助", isOn: $settings.colorBlindMode)
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var themeSection: some View {
        ThemePickerView()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("数据")
            VStack(spacing: 0) {
                infoRow(icon: "gamecontroller.fill", title: "总局数", value: "\(stats.gamesPlayed)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "trophy.fill", title: "胜利", value: "\(stats.gamesWon)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "percent", title: "胜率", value: stats.gamesPlayed > 0 ? "\(Int(stats.winRate))%" : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "flame.fill", title: "最佳连胜", value: "\(stats.bestStreak)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "number", title: "平均步数", value: stats.gamesWon > 0 ? String(format: "%.1f", stats.avgAttempts) : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "star.fill", title: "总星数", value: "\(progress.totalStars)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "checkmark.circle.fill", title: "关卡完成", value: "\(progress.completedLevels.count)/120")
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("成就")
            VStack(spacing: 0) {
                achievementRow("🔓", "初次破译", "完成第一局游戏", unlocked: stats.gamesWon >= 1)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("🔥", "连胜达人", "连续赢得 5 局", unlocked: stats.bestStreak >= 5)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("⭐", "三星特工", "任意关卡获得三星", unlocked: progress.starsByLevel.values.contains(3))
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("🎯", "百发百中", "连续赢得 10 局", unlocked: stats.bestStreak >= 10)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("🏆", "初级毕业", "完成全部初级特工关卡", unlocked: (1...20).allSatisfy { progress.completedLevels.contains($0) })
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("💎", "满星大师", "获得 100 颗星", unlocked: progress.totalStars >= 100)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                achievementRow("🧠", "解码宗师", "完成全部 120 关", unlocked: progress.completedLevels.count >= 120)
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("管理")
            VStack(spacing: 0) {
                Button {
                    showResetStatsAlert = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.warning)
                            .frame(width: 28)
                        Text("重置统计数据")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.warning)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert("确认重置统计？", isPresented: $showResetStatsAlert) {
                    Button("取消", role: .cancel) { }
                    Button("重置", role: .destructive) {
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                    }
                } message: { Text("胜率、连胜等数据将归零") }

                Divider().overlay(AppTheme.textMuted.opacity(0.2))

                Button {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.danger)
                            .frame(width: 28)
                        Text("重置全部进度")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.danger)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert("确认重置全部进度？", isPresented: $showResetAlert) {
                    Button("取消", role: .cancel) { }
                    Button("重置", role: .destructive) {
                        progress.completedLevels = []
                        progress.starsByLevel = [:]
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                        UserDefaults.standard.set(false, forKey: "tutorialSeen")
                    }
                } message: { Text("关卡、星级、统计数据全部清零，不可恢复") }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("关于")
            VStack(spacing: 0) {
                infoRow(icon: "info.circle.fill", title: "版本", value: "1.0.0")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "lock.shield.fill", title: "密码破译局", value: "Code Breaker")
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

    private func achievementRow(_ emoji: String, _ title: String, _ desc: String, unlocked: Bool) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
                .grayscale(unlocked ? 0 : 1)
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
