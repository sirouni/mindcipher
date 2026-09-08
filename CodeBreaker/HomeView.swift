import SwiftUI
import GameKit

struct HomeView: View {
    @State private var showLevels = false
    @State private var showFreePlay = false
    @State private var showDuel = false
    @State private var showOnline = false
    @State private var showSettings = false
    @State private var showDaily = false
    @State private var showEditor = false
    @State private var showLieMode = false
    @State private var showAchievements = false
    @State private var showLeaderboard = false
    @State private var showTutorial = false
    @State private var showLieTaste = false
    @State private var showStore = false
    @State private var showFeedback = false
    @ObservedObject private var gcManager = GameCenterManager.shared
    @ObservedObject private var challengeManager = ChallengeManager.shared
    @StateObject private var tasteModel = GameViewModel()
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("hasSeenLieTaste") private var hasSeenLieTaste = false
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    @State private var radarAngle: Double = 0
    @ObservedObject var progress = ProgressManager.shared
    @ObservedObject private var lieProgress = ProgressManager.lieShared
    @ObservedObject var stats = StatsManager.shared
    @ObservedObject var storeManager = StoreManager.shared
    @State private var paywallReason: PaywallReason?
    @State private var showFeedbackTip = false
    @State private var didOfferFeedbackTip = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                menuSection
                    .padding(.top, 10)
                Spacer(minLength: 8)
                statsBar
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .background(AppTheme.paper.ignoresSafeArea())
            .navigationDestination(isPresented: $showLevels) {
                LevelSelectView()
            }
            .navigationDestination(isPresented: $showFreePlay) {
                FreePlaySetupView()
            }
            .navigationDestination(isPresented: $showDuel) {
                DuelSetupView()
            }
            .navigationDestination(isPresented: $showOnline) {
                MultiplayerView()
            }
            .onReceive(gcManager.$pendingInvite) { invite in
                if FeatureFlags.onlineMatchEnabled, invite != nil { showOnline = true }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showStore) {
                StoreView()
            }
            .navigationDestination(isPresented: $showDaily) {
                DailyChallengeView()
            }
            .navigationDestination(isPresented: $showEditor) {
                LevelEditorView()
            }
            .navigationDestination(isPresented: $showLieMode) {
                LieLevelSelectView()
            }
            .navigationDestination(isPresented: $showAchievements) {
                AchievementsView()
            }
            .navigationDestination(isPresented: $showLieTaste) {
                GameView(viewModel: tasteModel)
            }
            .navigationDestination(isPresented: $showFeedback) {
                FeedbackView()
            }
            .onChange(of: challengeManager.pendingDaily) { _, pending in
                guard pending else { return }
                showDaily = true
                ChallengeManager.shared.pendingDaily = false
            }
            .onChange(of: showLieTaste) { _, presented in
                if !presented {
                    finishLieTasteIfNeeded()
                }
            }
            .sheet(isPresented: $showLeaderboard) {
                GameCenterLeaderboardView()
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .sheet(isPresented: $showTutorial, onDismiss: {
                hasSeenTutorial = true
                if !hasSeenLieTaste && !shouldSkipOnboarding {
                    beginLieTaste()
                } else {
                    scheduleFeedbackTip(waitForGameCenterBanner: false)
                }
            }) {
                TutorialView()
            }
            .onAppear {
                animateEntrance()
                AchievementManager.shared.checkAll()
                DailyStreakManager.shared.syncToAppGroup()
                if shouldSkipOnboarding {
                    hasSeenTutorial = true
                    hasSeenLieTaste = true
                    return
                }
                if !hasSeenTutorial && !hasSeenLieTaste {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        beginLieTaste()
                    }
                } else if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorial = true
                    }
                } else {
                    scheduleFeedbackTip(waitForGameCenterBanner: true)
                }
            }
        }
        .preferredColorScheme(ThemeManager.shared.currentSkin.colorScheme)
    }

    

    private var unlockedCount: Int { AchievementManager.shared.unlockedCount }
    private var totalAchievements: Int { AchievementManager.shared.totalCount }

    private var dailyCompleted: Bool {
        let key = "daily_\(dailyDateString)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private var dailyDateString: String { DailyCalendar.dayKey() }

    private var shouldSkipOnboarding: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-storeScreenshots") { return true }
        if let index = arguments.firstIndex(of: "-hasSeenTutorial"),
           arguments.indices.contains(index + 1) {
            let value = arguments[index + 1].lowercased()
            return value == "yes" || value == "true" || value == "1"
        }
        return false
    }

    private func beginLieTaste() {
        guard !showLieTaste else { return }
        tasteModel.startLieTaste()
        hasSeenLieTaste = true
        showLieTaste = true
    }

    private func finishLieTasteIfNeeded() {
        if !hasSeenTutorial {
            showTutorial = true
        } else {
            scheduleFeedbackTip(waitForGameCenterBanner: false)
        }
    }

    // MARK: - Header (file cover)

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                toolbarIcon("questionmark.circle", label: "Help") { showTutorial = true }
                if gcManager.isAuthenticated {
                    toolbarIcon("list.number", label: "Leaderboard") { showLeaderboard = true }
                }
                Spacer()
                feedbackHeaderButton
                    .overlay(alignment: .top) {
                        if showFeedbackTip {
                            feedbackTipBubble
                                .offset(y: 44)
                                .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
                        }
                    }
                    .zIndex(10)
                toolbarIcon("seal", label: L("store.title")) { showStore = true }
                toolbarIcon("gearshape", label: L("settings.title")) { showSettings = true }
            }
            .padding(.top, 4)
            .zIndex(10)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    DossierCaption(text: L("home.caption"))
                    Text(L("app.title"))
                        .font(AppFont.display(28, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                if storeManager.isPro {
                    StampView(text: L("store.clearance"), tone: .red, size: 8, rotation: -8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .opacity(titleOpacity)

            Rectangle().fill(AppTheme.ink).frame(height: 1.5)
                .opacity(titleOpacity)
        }
    }

    private func toolbarIcon(_ name: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 40, height: 40)
        }
        .accessibilityLabel(label)
    }

    private var feedbackHeaderButton: some View {
        Button {
            showFeedbackTip = false
            showFeedback = true
        } label: {
            Image(systemName: "text.bubble")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 40, height: 40)
        }
        .accessibilityLabel(L("menu.feedback"))
        .accessibilityIdentifier("home.feedback")
    }

    private var feedbackTipBubble: some View {
        VStack(spacing: 0) {
            FeedbackTipCaret()
                .fill(AppTheme.ink)
                .frame(width: 12, height: 6)
            Text(L("home.feedback.tip"))
                .font(AppFont.label(11, weight: .semibold))
                .foregroundStyle(AppTheme.paper)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
        }
        .onTapGesture {
            showFeedbackTip = false
            showFeedback = true
        }
        .accessibilityIdentifier("home.feedback.tip")
    }

    private func scheduleFeedbackTip(waitForGameCenterBanner: Bool) {
        guard !storeManager.isPro, !didOfferFeedbackTip, hasSeenTutorial else { return }
        didOfferFeedbackTip = true
        Task { @MainActor in
            if waitForGameCenterBanner {
                let timeout = Date().addingTimeInterval(6)
                while !gcManager.authenticationFinished && Date() < timeout {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                // System "Welcome back" banner covers the top of the screen.
                try? await Task.sleep(for: .seconds(4.5))
            } else {
                try? await Task.sleep(for: .seconds(0.8))
            }
            guard !showTutorial, !showFeedback else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                showFeedbackTip = true
            }
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation(.easeOut(duration: 0.22)) {
                showFeedbackTip = false
            }
        }
    }

    // MARK: - Index page

    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            todayCaseCard

            HStack(spacing: 10) {
                volumeCard(
                    caption: L("case.classic"),
                    title: L("menu.classic"),
                    done: progress.completedLevels.count,
                    total: 240,
                    lie: false,
                    accessibilityID: "home.classic"
                ) { showLevels = true }

                volumeCard(
                    caption: L("case.lie"),
                    title: L("menu.lie"),
                    done: lieProgress.completedLevels.count,
                    total: 240,
                    lie: true,
                    accessibilityID: "home.lie"
                ) { showLieMode = true }
            }

            DossierCaption(text: L("home.index"))
                .padding(.top, 6)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                indexRow(
                    numeral: 1, title: L("menu.free"), detail: L("menu.free.sub"),
                    requiresPro: true
                ) { if storeManager.isPro { showFreePlay = true } else { paywallReason = .freePlay } }
                indexRow(
                    numeral: 2, title: L("menu.duel"), detail: L("menu.duel.sub"),
                    accessibilityID: "home.duel"
                ) { showDuel = true }
                indexRow(
                    numeral: 3, title: L("menu.editor"), detail: L("menu.editor.sub"),
                    requiresPro: true
                ) { if storeManager.isPro { showEditor = true } else { paywallReason = .editor } }
                indexRow(
                    numeral: 4, title: L("menu.achievements"),
                    detail: L("home.unlocked", unlockedCount, totalAchievements),
                    accessibilityID: "home.achievements", last: !FeatureFlags.onlineMatchEnabled
                ) { showAchievements = true }
                if FeatureFlags.onlineMatchEnabled {
                    indexRow(numeral: 5, title: L("menu.online"), detail: L("menu.online.sub"), last: true) { showOnline = true }
                }
            }
            .paperCard()
        }
        .offset(y: buttonsOffset)
        .opacity(titleOpacity)
    }

    private var todayCaseCard: some View {
        let isLie = DailyCalendar.isLieDay()
        return Button { showDaily = true } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    DossierCaption(text: L("home.today"), color: isLie ? AppTheme.danger : AppTheme.textSecondary)
                    Text(L("case.no", DailyCalendar.dayNumber()))
                        .font(AppFont.display(24, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(dailyCompleted
                         ? L("menu.daily.done")
                         : (isLie ? L("menu.daily.lie") : L("menu.daily.todo")))
                        .font(AppFont.body(12))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 8) {
                    if dailyCompleted {
                        StampView(text: L("case.closed"), tone: .red, size: 10, rotation: -10)
                    } else if isLie {
                        StampView(text: "Top Secret", tone: .red, size: 10, rotation: -10)
                    } else {
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 32, height: 32)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppTheme.ink, lineWidth: 1))
                    }
                    if DailyStreakManager.shared.currentStreak > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(DailyStreakManager.shared.currentStreak)")
                                .font(AppFont.display(14, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(L("daily.attendance"))
                                .font(AppFont.label(9, weight: .regular))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard(fill: AppTheme.bgCardLight)
            .overlay(alignment: .leading) {
                Rectangle().fill(isLie ? AppTheme.danger : AppTheme.ink).frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.daily")
    }

    private func volumeCard(
        caption: String, title: String, done: Int, total: Int, lie: Bool,
        accessibilityID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    DossierCaption(text: caption, color: lie ? AppTheme.danger : AppTheme.textSecondary)
                    Spacer()
                    Text("\(L("home.volume")) I–VI")
                        .font(AppFont.label(9, weight: .regular))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Text(title)
                    .font(AppFont.display(16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 6)

                Text(L("levels.solved", done, total))
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(AppTheme.rule).frame(height: 2)
                        Rectangle().fill(lie ? AppTheme.danger : AppTheme.ink)
                            .frame(width: geo.size.width * CGFloat(min(1, Double(done) / Double(max(total, 1)))), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
    }

    private func indexRow(
        numeral: Int, title: String, detail: String,
        requiresPro: Bool = false,
        accessibilityID: String? = nil,
        last: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let locked = requiresPro && !storeManager.isPro
        return Button(action: action) {
            HStack(spacing: 10) {
                Text(romanNumeral(numeral))
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 26, alignment: .leading)
                Text(title)
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(locked ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(1)
                if locked {
                    Text("PRO")
                        .font(AppFont.label(8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(AppTheme.accent, lineWidth: 1))
                }
                Spacer(minLength: 6)
                Text(detail)
                    .font(AppFont.body(11))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: locked ? "lock" : "arrow.forward")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !last { TypewriterRule().padding(.horizontal, 14) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID ?? "")
    }

    // MARK: - Ledger line

    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(value: "\(stats.gamesPlayed)", label: L("stats.games"))
            ledgerDivider
            statItem(
                value: stats.gamesPlayed == 0 ? "--" : "\(Int(stats.winRate))%",
                label: L("stats.winrate")
            )
            ledgerDivider
            statItem(value: "\(stats.currentStreak)", label: L("stats.streak"))
            ledgerDivider
            statItem(value: "\(progress.totalStars)", label: L("stats.stars"))
            ledgerDivider
            statItem(value: "\(stats.bestStreak)", label: L("stats.best"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.ink).frame(height: 1) }
        .overlay(alignment: .bottom) { TypewriterRule() }
        .opacity(titleOpacity)
    }

    private var ledgerDivider: some View {
        Rectangle().fill(AppTheme.rule).frame(width: 1, height: 26)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFont.display(16, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(AppFont.label(8, weight: .regular))
                .tracking(0.8)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
            buttonsOffset = 0
        }
    }
}

private struct FeedbackTipCaret: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct FreePlaySetupView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var lieMode = false
    @State private var startGame = false
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()
            VStack(spacing: 20) {
                Text(L("game.free"))
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        difficultyRow(diff)
                    }
                }
                .padding(16)
                .paperCard()

                VStack(spacing: 8) {
                    infoRow(L("param.length"), "\(selectedDifficulty.codeLength)")
                    infoRow(L("param.colors"), "\(selectedDifficulty.colorCount)")
                    infoRow(L("param.attempts"), "\(selectedDifficulty.maxAttempts)")
                    infoRow(L("param.repeat"), selectedDifficulty.allowDuplicates ? L("param.yes") : L("param.no"))
                    if selectedDifficulty.hasTimeLimit {
                        infoRow(L("param.timelimit"), "\(selectedDifficulty.timeLimitSeconds)s")
                    }
                }
                .padding(16)
                .paperCard()

                HStack(spacing: 12) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(lieMode ? AppTheme.danger : AppTheme.textMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("lie.toggle"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(lieMode ? AppTheme.danger : AppTheme.textPrimary)
                        Text(L("lie.toggle.desc"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $lieMode)
                        .tint(AppTheme.danger)
                        .labelsHidden()
                }
                .padding(14)
                .paperCard()

                Spacer()

                Button {
                    viewModel.startFreePlay(difficulty: selectedDifficulty, lieMode: lieMode)
                    startGame = true
                } label: {
                    Text(lieMode ? L("lie.start") : L("game.start"))
                        .font(AppFont.display(18, weight: .bold))
                        .foregroundStyle(AppTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(lieMode ? AppTheme.danger : AppTheme.accent, in: RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(24)
        }
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    

    private func difficultyRow(_ diff: Difficulty) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedDifficulty = diff }
        } label: {
            HStack {
                Text(diff.localizedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selectedDifficulty == diff ? AppTheme.paper : AppTheme.textPrimary)
                Spacer()
                Text(diff.statsLabel)
                    .font(AppFont.mono(12))
                    .foregroundStyle(selectedDifficulty == diff ? AppTheme.paper.opacity(0.8) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(selectedDifficulty == diff ? AppTheme.ink : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.mono(14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

struct DuelSetupView: View {
    enum DuelPhase { case config, setting, handoff }

    @State private var phase: DuelPhase = .config
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var secretCode: [PegColor] = []
    @State private var startGame = false
    @State private var countDown = 3
    @StateObject private var viewModel = GameViewModel()

    private var codeLength: Int { selectedDifficulty.codeLength }
    private var colorCount: Int { selectedDifficulty.colorCount }
    private var maxAttempts: Int { selectedDifficulty.maxAttempts }
    private var availableColors: [PegColor] { Array(PegColor.allCases.prefix(colorCount)) }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            switch phase {
            case .config: configView
            case .setting: codeSetupView
            case .handoff: handoffView
            }
        }
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    // MARK: - 第1步：选难度

    private var configView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.ink)
                Text(L("duel.title"))
                    .font(AppFont.display(24, weight: .black))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L("duel.desc"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedDifficulty = diff }
                    } label: {
                        HStack {
                            Text(diff.localizedName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedDifficulty == diff ? AppTheme.paper : AppTheme.textPrimary)
                            Spacer()
                            Text(diff.statsLabel)
                                .font(AppFont.mono(11))
                                .foregroundStyle(selectedDifficulty == diff ? AppTheme.paper.opacity(0.7) : AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(selectedDifficulty == diff ? AppTheme.ink : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("duel.diff.\(diff.rawValue.lowercased())")
                }
            }
            .padding(12)
            .paperCard()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.ink)
                    Text(L("duel.rules"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    ruleText(L("duel.rule1"))
                    ruleText(L("duel.rule2"))
                    ruleText(L("duel.rule3"))
                    ruleText(L("duel.rule4"))
                }
            }
            .padding(14)
            .paperCard()

            Spacer()

            Button {
                secretCode = []
                withAnimation(.spring(response: 0.3)) { phase = .setting }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                    Text(L("duel.p1.setup"))
                }
                .font(AppFont.display(17, weight: .bold))
                .foregroundStyle(AppTheme.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
            }
        }
        .padding(24)
    }

    private func ruleText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppTheme.textSecondary)
    }

    // MARK: - 第2步：设密码

    private var codeSetupView: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) { phase = .config }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(L("duel.p1.setup"))
                        .font(AppFont.display(17, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(selectedDifficulty.localizedName) · \(selectedDifficulty.statsLabel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Color.clear.frame(width: 20)
            }

            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.bgCardLight)
                            .frame(height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(
                                        i == min(secretCode.count, codeLength - 1) ?
                                            AppTheme.ink : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        if i < secretCode.count {
                            PegView(color: secretCode[i], size: 34)
                        }
                    }
                    .onTapGesture {
                        if i < secretCode.count { secretCode.remove(at: i) }
                    }
                }
            }
            .boardLayout()

            Text(L("duel.tap"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(colorCount, 4)), spacing: 10) {
                ForEach(availableColors) { color in
                    Button {
                        if secretCode.count < codeLength { secretCode.append(color) }
                    } label: {
                        PegView(color: color, size: 44)
                    }
                    .disabled(secretCode.count >= codeLength)
                }
            }
            .padding(14)
            .paperCard()
            .boardLayout()

            Spacer()

            if secretCode.count == codeLength {
                Button {
                    withAnimation(.spring(response: 0.3)) { phase = .handoff }
                    startCountdown()
                } label: {
                    Text(L("duel.confirm"))
                        .font(AppFont.display(17, weight: .bold))
                        .foregroundStyle(AppTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
    }

    // MARK: - 第3步：交接

    private var handoffView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.warning)
            }

            VStack(spacing: 8) {
                Text(L("duel.handoff"))
                    .font(AppFont.display(24, weight: .black))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L("duel.handoff.desc"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ZStack {
                Circle()
                    .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 6)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: CGFloat(max(0, countDown)) / 3.0)
                    .stroke(AppTheme.ink,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                if countDown > 0 {
                    Text("\(countDown)")
                        .font(AppFont.display(40, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Spacer()

            if countDown <= 0 {
                VStack(spacing: 10) {
                    Text("\(selectedDifficulty.localizedName) · \(selectedDifficulty.statsLabel)")
                        .font(AppFont.mono(12))
                        .foregroundStyle(AppTheme.textSecondary)

                    Button {
                        viewModel.startDuel(secretCode: secretCode, colorCount: colorCount, maxAttempts: maxAttempts)
                        startGame = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                            Text(L("duel.p2.start"))
                        }
                        .font(AppFont.display(17, weight: .bold))
                        .foregroundStyle(AppTheme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
    }

    private func startCountdown() {
        countDown = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countDown -= 1
            if countDown <= 0 { timer.invalidate() }
        }
    }
}
