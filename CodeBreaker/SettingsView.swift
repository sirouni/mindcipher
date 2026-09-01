import SwiftUI
import CoreImage.CIFilterBuiltins

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
    @ObservedObject var store = StoreManager.shared
    @State private var showResetAlert = false
    @State private var showResetStatsAlert = false
    @State private var showFeedback = false

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    gameSection
                    themeSection
                    supportSection
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
        .navigationDestination(isPresented: $showFeedback) {
            FeedbackView()
        }
    }

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Game")
            VStack(spacing: 0) {
                toggleRow(icon: "speaker.wave.2.fill", title: "Sound", isOn: $settings.soundEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", isOn: $settings.hapticsEnabled)
                #if DEBUG
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "checkmark.seal.fill", title: "Unlock Pro (Debug)", isOn: $store.isPro)
                #endif
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var themeSection: some View {
        ThemePickerView()
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(L("feedback.section"))
            VStack(spacing: 0) {
                Button {
                    showFeedback = true
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 28)
                        Text(L("feedback.row"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("feedback.row"))
                .accessibilityIdentifier("feedback.row")
            }
            .glassCard(cornerRadius: 14)
        }
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
                infoRow(icon: "checkmark.circle.fill", title: "Levels done", value: "\(progress.completedLevels.count + ProgressManager.lieShared.completedLevels.count)/480")
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
        NavigationLink(destination: AchievementDetailView(achievement: a, unlocked: unlocked)) {
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
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: Achievement
    let unlocked: Bool
    private let appStoreURL = "https://apps.apple.com/app/mind-cipher/id6777428188"

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    achievementHero
                    achievementInfo
                    shareButton
                }
                .padding(24)
            }
        }
        .navigationTitle(achievement.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var achievementHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppTheme.warning.opacity(0.2) : Color.black.opacity(0.06))
                    .frame(width: 100, height: 100)
                if unlocked {
                    Circle()
                        .stroke(AppTheme.warning.opacity(0.4), lineWidth: 3)
                        .frame(width: 110, height: 110)
                }
                Image(systemName: achievement.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(unlocked ? AppTheme.warning : AppTheme.textMuted)
                    .opacity(unlocked ? 1 : 0.4)
            }

            VStack(spacing: 6) {
                Text(achievement.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                Text(achievement.category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.1), in: Capsule())
            }
        }
        .padding(.top, 20)
    }

    private var achievementInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(AppTheme.textSecondary)
                Text(achievement.desc)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            HStack {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? AppTheme.accent : AppTheme.textMuted)
                Text(unlocked ? "Unlocked" : "Locked")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(unlocked ? AppTheme.accent : AppTheme.textMuted)
                Spacer()
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }

    private var shareButton: some View {
        Button {
            shareAchievement()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(unlocked ? AppTheme.accent : AppTheme.textMuted, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.6)
    }

    private func shareAchievement() {
        let card = AchievementShareCard(
            achievement: achievement,
            appStoreURL: appStoreURL
        )

        let renderer = ImageRenderer(content: card.frame(width: 360))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }

        let text = "I unlocked \"\(achievement.title)\" in Mind Cipher! \(achievement.desc)"

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = root.view
        root.present(vc, animated: true)
    }
}

// MARK: - Achievement Share Card

struct AchievementShareCard: View {
    let achievement: Achievement
    let appStoreURL: String

    private let bgLight = Color(red: 0.92, green: 0.95, blue: 0.98)
    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let gold = Color(red: 0.90, green: 0.52, blue: 0.05)

    var body: some View {
        VStack(spacing: 20) {
            Text("ACHIEVEMENT UNLOCKED")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .tracking(1.5)
                .padding(.top, 24)

            ZStack {
                Circle()
                    .fill(gold.opacity(0.15))
                    .frame(width: 90, height: 90)
                Circle()
                    .stroke(gold.opacity(0.4), lineWidth: 2.5)
                    .frame(width: 100, height: 100)
                Image(systemName: achievement.icon)
                    .font(.system(size: 38))
                    .foregroundStyle(gold)
            }

            VStack(spacing: 6) {
                Text(achievement.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.12))
                Text(achievement.desc)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                Text(achievement.category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.1), in: Capsule())
            }

            Divider().padding(.horizontal, 30)

            HStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mind Cipher")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.2))
                    Text("Scan to download")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(white: 0.5))
                }
                Spacer()
                if let qr = generateQRCode(from: appStoreURL) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(bgLight)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 256.0 / ciImage.extent.width
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
