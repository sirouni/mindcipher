import SwiftUI

struct LevelSelectView: View {
    var body: some View { FilingCabinetView(lieMode: false) }
}

/// Six drawers (difficulty tiers), forty case folders each.
struct FilingCabinetView: View {
    let lieMode: Bool

    let levelManager = LevelManager.shared
    @ObservedObject var progress: ProgressManager
    @ObservedObject var store = StoreManager.shared
    @ObservedObject private var gcManager = GameCenterManager.shared
    @State private var selectedTier = 0
    @State private var startGame = false
    @State private var previewLevel: Level?
    @State private var showPaywall = false
    @State private var showLeaderboard = false
    @StateObject private var viewModel = GameViewModel()

    init(lieMode: Bool) {
        self.lieMode = lieMode
        self.progress = lieMode ? ProgressManager.lieShared : ProgressManager.shared
    }

    private var tiers: [[Level]] { levelManager.tiers }
    private var currentTier: [Level] { tiers[selectedTier] }
    private var tierDiff: String { currentTier.first?.difficulty.localizedName ?? "" }
    private var tierDone: Int { currentTier.filter { progress.completedLevels.contains($0.id) }.count }
    private var tone: Color { lieMode ? AppTheme.danger : AppTheme.ink }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                cabinetHeader
                drawerTabs
                TabView(selection: $selectedTier) {
                    ForEach(0..<tiers.count, id: \.self) { i in
                        folderGrid(levels: tiers[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.3), value: selectedTier)
            }

            if let level = previewLevel {
                levelPreviewOverlay(level)
            }
        }
        .navigationTitle(lieMode ? L("menu.lie") : L("menu.classic"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
        .toolbar {
            if gcManager.isAuthenticated {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLeaderboard = true } label: {
                        Image(systemName: "list.number")
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .accessibilityLabel("Leaderboard")
                }
            }
        }
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
        .sheet(isPresented: $showLeaderboard) {
            GameCenterLeaderboardView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: lieMode ? .lieLevels : .classicLevels)
        }
    }

    // MARK: - Header + drawers

    private var cabinetHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                DossierCaption(text: L("levels.cabinet"), color: lieMode ? AppTheme.danger : AppTheme.textSecondary)
                Text(lieMode ? L("case.lie") : L("case.classic"))
                    .font(AppFont.display(20, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 8)
            Text(L("levels.solved", progress.completedLevels.count, 240))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var drawerTabs: some View {
        VStack(spacing: 8) {
        HStack(spacing: 4) {
            ForEach(0..<tiers.count, id: \.self) { i in
                let selected = i == selectedTier
                let done = tiers[i].filter { progress.completedLevels.contains($0.id) }.count
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTier = i }
                } label: {
                    VStack(spacing: 3) {
                        Text(romanNumeral(i + 1))
                            .font(AppFont.label(12, weight: .bold))
                            .foregroundStyle(selected ? AppTheme.paper : AppTheme.textPrimary)
                        Rectangle()
                            .fill(done == tiers[i].count ? AppTheme.accent : (selected ? AppTheme.paper.opacity(0.6) : AppTheme.rule))
                            .frame(width: 14, height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(selected ? tone : AppTheme.bgCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(selected ? tone : AppTheme.rule, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("levels.drawer", romanNumeral(i + 1)))
            }
        }
        .padding(.horizontal, 20)

            HStack {
                Text("\(L("levels.drawer", romanNumeral(selectedTier + 1))) · \(tierDiff)")
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(tierDone)/\(currentTier.count)")
                    .font(AppFont.mono(11, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 6)
    }

    // MARK: - Folder grid

    private func folderGrid(levels: [Level]) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
        return ScrollView {
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(levels) { level in
                    folderCell(level)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
    }

    private func folderCell(_ level: Level) -> some View {
        let isCompleted = progress.completedLevels.contains(level.id)
        let isUnlocked = progress.isUnlocked(level: level.id)
        let isProLocked = store.isLevelLocked(level.id, lieMode: lieMode)
        let stars = progress.starsByLevel[level.id] ?? 0
        let isNext = !isCompleted && isUnlocked && !isProLocked

        return Button {
            if isProLocked {
                showPaywall = true
            } else if isUnlocked {
                withAnimation(.spring(response: 0.3)) { previewLevel = level }
            }
        } label: {
            VStack(spacing: 4) {
                // Folder tab
                HStack {
                    Rectangle()
                        .fill(isNext ? tone : AppTheme.rule)
                        .frame(width: 18, height: 3)
                    Spacer()
                }
                .padding(.horizontal, 6)

                Text("\(level.id)")
                    .font(AppFont.display(16, weight: .bold))
                    .foregroundStyle(
                        isProLocked || !isUnlocked ? AppTheme.textMuted : AppTheme.textPrimary
                    )

                Group {
                    if isCompleted {
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < stars ? "star.fill" : "star")
                                    .font(.system(size: 7))
                                    .foregroundStyle(i < stars ? AppTheme.accent : AppTheme.textMuted.opacity(0.5))
                            }
                        }
                    } else if isProLocked {
                        Text("PRO")
                            .font(AppFont.label(7, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(AppTheme.accent)
                    } else if !isUnlocked {
                        Image(systemName: "lock")
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.textMuted)
                    } else {
                        Color.clear.frame(height: 9)
                    }
                }
                .frame(height: 10)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(isCompleted ? AppTheme.paperFolder : AppTheme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isNext ? tone : AppTheme.rule, lineWidth: isNext ? 1.5 : 1)
            )
            .overlay {
                if isCompleted {
                    Circle()
                        .stroke(AppTheme.accent, lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-10))
                        .opacity(0.75)
                        .offset(y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && !isProLocked)
        .accessibilityLabel("\(L("case.no", level.id))\(isCompleted ? ", \(L("case.closed"))" : "")")
    }

    // MARK: - Preview

    private func totalAttempts(for level: Level) -> Int {
        lieMode ? level.maxAttempts + level.difficulty.lieExtraAttempts : level.maxAttempts
    }

    private func levelPreviewOverlay(_ level: Level) -> some View {
        ZStack {
            AppTheme.ink.opacity(0.4).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.3)) { previewLevel = nil } }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        DossierCaption(text: lieMode ? L("case.lie") : L("case.classic"), color: lieMode ? AppTheme.danger : AppTheme.textSecondary)
                        Text(L("case.no", level.id))
                            .font(AppFont.display(24, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(level.difficulty.localizedName)
                            .font(AppFont.label(11, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if progress.completedLevels.contains(level.id) {
                        StampView(text: L("case.closed"), tone: .red, size: 10, rotation: -10)
                    } else if lieMode {
                        StampView(text: "Top Secret", tone: .red, size: 10, rotation: -10)
                    }
                }
                Rectangle().fill(AppTheme.ink).frame(height: 1.5)

                VStack(spacing: 0) {
                    previewRow(L("param.length"), "\(level.codeLength)")
                    previewRow(L("param.colors"), "\(level.colorCount)")
                    previewRow(L("param.attempts"), "\(totalAttempts(for: level))")
                    previewRow(L("param.repeat"), level.allowDuplicates ? L("param.yes") : L("param.no"), last: !lieMode && level.timeLimitSeconds == 0)
                    if lieMode {
                        previewRow(L("param.fake"), "1", last: level.timeLimitSeconds == 0)
                    }
                    if level.timeLimitSeconds > 0 {
                        previewRow(L("param.timelimit"), "\(level.timeLimitSeconds)s", last: true)
                    }
                }

                let stars = progress.starsByLevel[level.id] ?? 0
                if stars > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundStyle(i < stars ? AppTheme.accent : AppTheme.textMuted)
                        }
                    }
                }

                Button {
                    if lieMode {
                        viewModel.startLieGame(level: level, totalAttempts: totalAttempts(for: level))
                    } else {
                        viewModel.startGame(level: level)
                    }
                    previewLevel = nil
                    startGame = true
                } label: {
                    Text(progress.completedLevels.contains(level.id) ? L("result.retry") : L("level.start"))
                }
                .buttonStyle(InkButtonStyle())
            }
            .padding(22)
            .paperCard(fill: AppTheme.bgCardLight)
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
    }

    private func previewRow(_ label: String, _ value: String, last: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.mono(13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { if !last { TypewriterRule() } }
    }
}
