import SwiftUI

struct HomeView: View {
    @State private var showLevels = false
    @State private var showFreePlay = false
    @State private var showDuel = false
    @State private var showSettings = false
    @State private var showDaily = false
    @State private var showEditor = false
    @State private var showLieMode = false
    @State private var showTutorial = false
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    @State private var radarAngle: Double = 0
    @ObservedObject var progress = ProgressManager.shared
    @ObservedObject var stats = StatsManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bgGradient.ignoresSafeArea()
                ScanlineEffect().ignoresSafeArea().opacity(0.5)

                VStack(spacing: 0) {
                    settingsButton
                    Spacer()
                    headerSection
                    Spacer().frame(height: 20)
                    dailyBanner
                    Spacer().frame(height: 16)
                    menuSection
                    Spacer()
                    statsBar
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showLevels) {
                LevelSelectView()
            }
            .navigationDestination(isPresented: $showFreePlay) {
                FreePlaySetupView()
            }
            .navigationDestination(isPresented: $showDuel) {
                DuelSetupView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
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
            .sheet(isPresented: $showTutorial) {
                TutorialView()
            }
            .onAppear { animateEntrance() }
        }
        .preferredColorScheme(.dark)
    }

    private var settingsButton: some View {
        HStack {
            Button { showTutorial = true } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .glassCard(cornerRadius: 10)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .glassCard(cornerRadius: 10)
            }
        }
        .padding(.top, 4)
        .opacity(titleOpacity)
    }

    private var dailyBanner: some View {
        menuButton(
            title: "每日挑战",
            subtitle: dailyCompleted ? L("menu.daily.done") : L("menu.daily.todo"),
            icon: "calendar.badge.clock",
            color: AppTheme.warning
        ) { showDaily = true }
        .opacity(titleOpacity)
    }

    private var dailyCompleted: Bool {
        let key = "daily_\(dailyDateString)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private var dailyDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(AppTheme.accent.opacity(0.08), lineWidth: 1)
                    .frame(width: 200, height: 200)

                radarSweep
                    .frame(width: 160, height: 160)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)
                    .shadow(color: AppTheme.accent.opacity(0.5), radius: 20)
            }
            .scaleEffect(titleScale)
            .opacity(titleOpacity)

            VStack(spacing: 6) {
                Text(L("app.title"))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(L("app.subtitle"))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
                    .tracking(6)

                MorseIndicator(isActive: true)
                    .padding(.top, 4)
            }
            .opacity(titleOpacity)
        }
    }

    private var radarSweep: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(
                AngularGradient(
                    colors: [AppTheme.accent.opacity(0.3), .clear],
                    center: .center
                ),
                lineWidth: 60
            )
            .rotationEffect(.degrees(radarAngle))
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    radarAngle = 360
                }
            }
    }

    private var menuSection: some View {
        VStack(spacing: 14) {
            menuButton(
                title: L("menu.classic"),
                subtitle: L("menu.classic.sub"),
                icon: "target",
                color: AppTheme.accent
            ) { showLevels = true }

            menuButton(
                title: L("menu.lie"),
                subtitle: L("menu.lie.sub"),
                icon: "theatermask.and.paintbrush.fill",
                color: AppTheme.danger
            ) { showLieMode = true }

            menuButton(
                title: L("menu.free"),
                subtitle: L("menu.free.sub"),
                icon: "infinity",
                color: AppTheme.warning
            ) { showFreePlay = true }

            menuButton(
                title: L("menu.duel"),
                subtitle: L("menu.duel.sub"),
                icon: "person.2.fill",
                color: Color(red: 0.5, green: 0.5, blue: 1.0)
            ) { showDuel = true }

            menuButton(
                title: L("menu.editor"),
                subtitle: L("menu.editor.sub"),
                icon: "slider.horizontal.3",
                color: Color(red: 0.9, green: 0.4, blue: 0.6)
            ) { showEditor = true }
        }
        .offset(y: buttonsOffset)
        .opacity(titleOpacity)
    }

    private func menuButton(
        title: String, subtitle: String, icon: String, color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(16)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var statsBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                statItem(value: "\(stats.gamesPlayed)", label: L("stats.games"))
                Divider().frame(height: 30).overlay(AppTheme.textMuted)
                statItem(
                    value: stats.gamesPlayed == 0 ? "--" : "\(Int(stats.winRate))%",
                    label: L("stats.winrate")
                )
                Divider().frame(height: 30).overlay(AppTheme.textMuted)
                statItem(value: "\(stats.currentStreak)", label: L("stats.streak"))
                Divider().frame(height: 30).overlay(AppTheme.textMuted)
                statItem(value: "\(progress.totalStars)", label: L("stats.stars"))
            }

            if stats.currentStreak > 0 || stats.bestStreak > 0 {
                HStack(spacing: 12) {
                    if stats.currentStreak >= 3 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.danger)
                                .modifier(PulseAnimation())
                            Text("连胜 \(stats.currentStreak)!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.danger)
                        }
                    }
                    if stats.bestStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.warning)
                            Text("最佳 \(stats.bestStreak)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .glassCard(cornerRadius: 20)
        .padding(.bottom, 8)
        .opacity(titleOpacity)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            buttonsOffset = 0
        }
    }
}

struct FreePlaySetupView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var lieMode = false
    @State private var startGame = false
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("自由模式")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        difficultyRow(diff)
                    }
                }
                .padding(16)
                .glassCard()

                VStack(spacing: 8) {
                    infoRow("密码长度", "\(selectedDifficulty.codeLength) 位")
                    infoRow("可用颜色", "\(selectedDifficulty.colorCount) 种")
                    infoRow("最大尝试", "\(selectedDifficulty.maxAttempts) 次")
                    infoRow("允许重复", selectedDifficulty.allowDuplicates ? "是" : "否")
                    if selectedDifficulty.hasTimeLimit {
                        infoRow("时间限制", "\(selectedDifficulty.timeLimitSeconds) 秒")
                    }
                }
                .padding(16)
                .glassCard()

                HStack(spacing: 12) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(lieMode ? AppTheme.danger : AppTheme.textMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("谎言模式")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(lieMode ? AppTheme.danger : AppTheme.textPrimary)
                        Text("含1次虚假反馈")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $lieMode)
                        .tint(AppTheme.danger)
                        .labelsHidden()
                }
                .padding(14)
                .glassCard(cornerRadius: 14)

                Spacer()

                Button {
                    viewModel.startFreePlay(difficulty: selectedDifficulty, lieMode: lieMode)
                    startGame = true
                } label: {
                    Text(lieMode ? "开始谎言挑战" : "开始挑战")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(lieMode ? .white : AppTheme.bgDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(lieMode ? AppTheme.danger : AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
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
                Text(diff.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selectedDifficulty == diff ? AppTheme.bgDark : AppTheme.textPrimary)
                Spacer()
                Text("\(diff.codeLength)位·\(diff.colorCount)色")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(selectedDifficulty == diff ? AppTheme.bgDark.opacity(0.7) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDifficulty == diff ? AppTheme.accent : Color.clear)
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
                .font(.system(size: 14, weight: .bold, design: .monospaced))
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
            AppTheme.bgGradient.ignoresSafeArea()

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
                    .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 1.0))
                Text("双人对战")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("一人设密码，一人来破译")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedDifficulty = diff }
                    } label: {
                        HStack {
                            Text(diff.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedDifficulty == diff ? .white : AppTheme.textPrimary)
                            Spacer()
                            Text("\(diff.codeLength)位·\(diff.colorCount)色·\(diff.maxAttempts)步")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(selectedDifficulty == diff ? .white.opacity(0.7) : AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedDifficulty == diff ? Color(red: 0.5, green: 0.5, blue: 1.0) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .glassCard()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 1.0))
                    Text("对战规则")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    ruleText("1. 玩家1 秘密设置一组颜色密码")
                    ruleText("2. 将手机交给 玩家2")
                    ruleText("3. 玩家2 在限定步数内破译密码")
                    ruleText("4. 步数越少越厉害！")
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            Spacer()

            Button {
                secretCode = []
                withAnimation(.spring(response: 0.3)) { phase = .setting }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                    Text("玩家 1 设置密码")
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.5, green: 0.5, blue: 1.0), in: RoundedRectangle(cornerRadius: 14))
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
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("玩家 1 设置密码")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(selectedDifficulty.rawValue) · \(codeLength)位\(colorCount)色")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Color.clear.frame(width: 20)
            }

            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.bgCardLight)
                            .frame(height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        i == min(secretCode.count, codeLength - 1) ?
                                            Color(red: 0.5, green: 0.5, blue: 1.0) : Color.clear,
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

            Text("点击颜色添加，点击槽位移除")
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
            .glassCard()

            Spacer()

            if secretCode.count == codeLength {
                Button {
                    withAnimation(.spring(response: 0.3)) { phase = .handoff }
                    startCountdown()
                } label: {
                    Text("密码已设好 →")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.5, green: 0.5, blue: 1.0), in: RoundedRectangle(cornerRadius: 14))
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
                Text("请将手机交给对手")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("密码已锁定，请勿偷看！")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ZStack {
                Circle()
                    .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 6)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: CGFloat(max(0, countDown)) / 3.0)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 1.0),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                if countDown > 0 {
                    Text("\(countDown)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 1.0))
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Spacer()

            if countDown <= 0 {
                VStack(spacing: 10) {
                    Text("\(selectedDifficulty.rawValue) · \(codeLength)位\(colorCount)色 · \(maxAttempts)步")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)

                    Button {
                        viewModel.startDuel(secretCode: secretCode, colorCount: colorCount, maxAttempts: maxAttempts)
                        startGame = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                            Text("玩家 2 开始破译")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.5, green: 0.5, blue: 1.0), in: RoundedRectangle(cornerRadius: 14))
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
