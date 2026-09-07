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
    @State private var showLanguage = false
    @ObservedObject private var language = LanguageManager.shared

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let build, !build.isEmpty { return "\(version) (\(build))" }
        return version
    }

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
        .navigationTitle(L("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
        .navigationDestination(isPresented: $showFeedback) {
            FeedbackView()
        }
        .navigationDestination(isPresented: $showLanguage) {
            LanguageSettingsView()
        }
    }

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(L("settings.game"))
            VStack(spacing: 0) {
                toggleRow(icon: "speaker.wave.2.fill", title: L("settings.sound"), isOn: $settings.soundEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "iphone.radiowaves.left.and.right", title: L("settings.haptics"), isOn: $settings.hapticsEnabled)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                languageRow
                #if DEBUG
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                toggleRow(icon: "checkmark.seal.fill", title: L("settings.debug.pro"), isOn: $store.isPro)
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
                        Image(systemName: "chevron.forward")
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
            sectionHeader(L("settings.stats"))
            VStack(spacing: 0) {
                infoRow(icon: "gamecontroller.fill", title: L("stats.games"), value: "\(stats.gamesPlayed)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "trophy.fill", title: L("settings.wins"), value: "\(stats.gamesWon)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "percent", title: L("stats.winrate"), value: stats.gamesPlayed > 0 ? "\(Int(stats.winRate))%" : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "flame.fill", title: L("settings.beststreak"), value: "\(stats.bestStreak)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "number", title: L("settings.avg"), value: stats.gamesWon > 0 ? String(format: "%.1f", stats.avgAttempts) : "--")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "star.fill", title: L("stats.stars"), value: "\(progress.totalStars)")
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "checkmark.circle.fill", title: L("settings.levels"), value: "\(progress.completedLevels.count + ProgressManager.lieShared.completedLevels.count)/480")
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(L("settings.manage"))
            VStack(spacing: 0) {
                Button {
                    showResetStatsAlert = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.warning)
                            .frame(width: 28)
                        Text(L("settings.reset.stats"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.warning)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert(L("settings.reset.stats.q"), isPresented: $showResetStatsAlert) {
                    Button(L("settings.cancel"), role: .cancel) { }
                    Button(L("settings.reset"), role: .destructive) {
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                    }
                } message: { Text(L("settings.reset.stats.msg")) }

                Divider().overlay(AppTheme.textMuted.opacity(0.2))

                Button {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.danger)
                            .frame(width: 28)
                        Text(L("settings.reset.all"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.danger)
                        Spacer()
                    }
                    .padding(14)
                }
                .alert(L("settings.reset.all.q"), isPresented: $showResetAlert) {
                    Button(L("settings.cancel"), role: .cancel) { }
                    Button(L("settings.reset"), role: .destructive) {
                        progress.completedLevels = []
                        progress.starsByLevel = [:]
                        stats.gamesPlayed = 0; stats.gamesWon = 0
                        stats.currentStreak = 0; stats.bestStreak = 0; stats.totalAttempts = 0
                        UserDefaults.standard.set(false, forKey: "tutorialSeen")
                    }
                } message: { Text(L("settings.reset.all.msg")) }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(L("settings.about"))
            VStack(spacing: 0) {
                infoRow(icon: "info.circle.fill", title: L("settings.version"), value: appVersionLabel)
                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                infoRow(icon: "lock.shield.fill", title: L("app.title"), value: L("app.title"))
            }
            .glassCard(cornerRadius: 14)
        }
    }

    // MARK: - Row Components

    private var languageRow: some View {
        Button {
            showLanguage = true
        } label: {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28)
                Text(L("settings.language"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(language.preference == .system ? L("settings.language.system") : language.preference.nativeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("settings.language"))
    }

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

struct LanguageSettingsView: View {
    @ObservedObject private var language = LanguageManager.shared

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("settings.language"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)
                        .padding(.leading, 4)
                        .padding(.bottom, 2)

                    VStack(spacing: 0) {
                        ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, lang in
                            if index > 0 {
                                Divider().overlay(AppTheme.textMuted.opacity(0.2))
                            }
                            languageRow(lang)
                        }
                    }
                    .glassCard(cornerRadius: 14)
                }
                .padding(20)
            }
        }
        .navigationTitle(L("settings.language"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
    }

    private func languageRow(_ lang: AppLanguage) -> some View {
        let selected = language.preference == lang
        return Button {
            language.preference = lang
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang == .system ? L("settings.language.system") : lang.nativeName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    if lang == .system {
                        Text(language.resolvedLanguage.nativeName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .navigationTitle(L("menu.achievements"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
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
                        .fill(AppTheme.cardStroke)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.accent)
                        .frame(width: geo.size.width * CGFloat(manager.unlockedCount) / CGFloat(max(1, manager.totalCount)), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)

            Text(L("settings.unlocked"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private func categorySection(_ cat: AchievementCategory, items: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cat.localizedName)
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
                        .fill(unlocked ? AppTheme.warning.opacity(0.15) : AppTheme.cardStroke)
                        .frame(width: 42, height: 42)
                    Image(systemName: a.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(unlocked ? AppTheme.warning : AppTheme.textMuted)
                        .opacity(unlocked ? 1 : 0.3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(a.localizedTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                    Text(a.localizedDesc)
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
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("achieve.\(a.id)")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("achieve.\(a.id)")
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
        .navigationTitle(achievement.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
    }

    private var achievementHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppTheme.warning.opacity(0.2) : AppTheme.cardStroke)
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
                Text(achievement.localizedTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textMuted)
                Text(achievement.category.localizedName)
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
                Text(achievement.localizedDesc)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            HStack {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? AppTheme.accent : AppTheme.textMuted)
                Text(unlocked ? L("settings.unlocked") : L("settings.locked"))
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
                Text(L("result.share"))
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

        let text = L("share.achievement.text", achievement.localizedTitle, achievement.localizedDesc)

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
            Text(L("share.achievement.header"))
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
                Text(achievement.localizedTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.12))
                Text(achievement.localizedDesc)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                Text(achievement.category.localizedName)
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
                    Text(L("app.title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.2))
                    Text(L("share.scan"))
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
