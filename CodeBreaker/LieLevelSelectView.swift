import SwiftUI

struct LieLevelSelectView: View {
    let levelManager = LevelManager.shared
    @ObservedObject var progress = ProgressManager.lieShared
    @ObservedObject var store = StoreManager.shared
    @ObservedObject private var gcManager = GameCenterManager.shared
    @State private var selectedTier = 0
    @State private var startGame = false
    @State private var previewLevel: Level?
    @State private var showPaywall = false
    @State private var showLeaderboard = false
    @StateObject private var viewModel = GameViewModel()

    private var tiers: [[Level]] { levelManager.tiers }
    private var currentTier: [Level] { tiers[selectedTier] }
    private var tierDiff: String { currentTier.first?.difficulty.rawValue ?? "" }
    private var tierDone: Int { currentTier.filter { progress.completedLevels.contains($0.id) }.count }

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                lieHeader
                tierSwitcher
                TabView(selection: $selectedTier) {
                    ForEach(0..<tiers.count, id: \.self) { i in
                        tierGridView(for: i)
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
        .navigationTitle(L("lie.task"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            if gcManager.isAuthenticated {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLeaderboard = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(AppTheme.warning)
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
    }

    private var lieHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.danger)
            Text("1 fake feedback per level")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.danger)
            Spacer()
            Text("\(progress.completedLevels.count)/240")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.danger.opacity(0.08))
    }

    private var tierSwitcher: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) { selectedTier = max(0, selectedTier - 1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedTier > 0 ? AppTheme.danger : Color.black.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedTier == 0)

            Spacer()
            VStack(spacing: 4) {
                Text(tierDiff)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                Text("\(tierDone)/\(currentTier.count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { selectedTier = min(tiers.count - 1, selectedTier + 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedTier < tiers.count - 1 ? AppTheme.danger : Color.black.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedTier >= tiers.count - 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func tierGridView(for tierIndex: Int) -> some View {
        let cols = 5; let levels = tiers[tierIndex]
        let rows = (levels.count + cols - 1) / cols; let color = AppTheme.danger
        let lineInactive = Color.black.opacity(0.15)

        return ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { col in
                            let idx = row * cols + col
                            if idx < levels.count { levelCell(levels[idx]) }
                            else { Color.clear.frame(width: 56, height: 56) }
                            if col < cols - 1 {
                                let curIdx = row * cols + col
                                let nextIdx = curIdx + 1
                                let linked = nextIdx < levels.count &&
                                    progress.completedLevels.contains(levels[curIdx].id)
                                Rectangle()
                                    .fill(linked ? color : lineInactive)
                                    .frame(height: 3)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    if row < rows - 1 {
                        let lastInRow = row * cols + cols - 1
                        let firstInNext = (row + 1) * cols
                        let linked = lastInRow < levels.count && firstInNext < levels.count &&
                            progress.completedLevels.contains(levels[lastInRow].id)
                        let lineColor = linked ? color : lineInactive

                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle().fill(lineColor).frame(width: 3, height: 16)
                        }
                        .padding(.horizontal, 26)

                        HStack(spacing: 0) {
                            Rectangle().fill(lineColor).frame(height: 3)
                        }
                        .padding(.horizontal, 26)

                        HStack(spacing: 0) {
                            Rectangle().fill(lineColor).frame(width: 3, height: 16)
                            Spacer()
                        }
                        .padding(.horizontal, 26)
                    }
                }
            }.padding(12)
        }
    }

    private func levelCell(_ level: Level) -> some View {
        let isCompleted = progress.completedLevels.contains(level.id)
        let isUnlocked = progress.isUnlocked(level: level.id)
        let isProLocked = store.isLevelLocked(level.id)
        let stars = progress.starsByLevel[level.id] ?? 0
        let isNext = !isCompleted && isUnlocked

        return Button {
            if isProLocked {
                showPaywall = true
            } else if isUnlocked {
                withAnimation(.spring(response: 0.3)) { previewLevel = level }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isCompleted ? AppTheme.danger.opacity(0.25) :
                        isNext ? AppTheme.danger.opacity(0.15) :
                        AppTheme.bgCard.opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isNext ? AppTheme.danger :
                                isCompleted ? AppTheme.danger.opacity(0.4) :
                                Color.black,
                                lineWidth: isNext ? 2 : 1
                            )
                    )

                VStack(spacing: 3) {
                    Text("\(level.id)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(isCompleted ? AppTheme.danger : isProLocked ? AppTheme.textMuted : AppTheme.textPrimary)
                    if isCompleted {
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < stars ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted.opacity(0.4))
                            }
                        }
                    } else if isProLocked {
                        Text("PRO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.warning, in: Capsule())
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && !isProLocked)
        .sheet(isPresented: $showPaywall) {
            NavigationStack { StoreView() }
        }
    }

    private func levelPreviewOverlay(_ level: Level) -> some View {
        let extraAttempts: Int = {
            switch level.difficulty {
            case .beginner: return 5
            case .easy: return 7
            case .medium: return 8
            case .hard: return 7
            case .expert: return 7
            case .master: return 5
            }
        }()
        let totalAttempts = level.maxAttempts + extraAttempts

        return ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.3)) { previewLevel = nil } }

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .foregroundStyle(AppTheme.danger)
                    Text("Lie Level \(level.id)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text(level.difficulty.rawValue)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.danger.opacity(0.15), in: Capsule())

                VStack(spacing: 6) {
                    previewRow("Code length", "\(level.codeLength)")
                    previewRow("Colors", "\(level.colorCount)")
                    previewRow("Max attempts", "\(totalAttempts)")
                    previewRow("Allow repeats", level.allowDuplicates ? "Yes" : "No")
                    previewRow("Fake feedback", "1")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.96))
                )

                let stars = progress.starsByLevel[level.id] ?? 0
                if stars > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted)
                        }
                    }
                }

                Button {
                    viewModel.startLieGame(level: level, totalAttempts: totalAttempts)
                    previewLevel = nil
                    startGame = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                            .font(.system(size: 14))
                        Text(progress.completedLevels.contains(level.id) ? "Retry" : "Start")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(AppTheme.danger, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 4)
            )
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
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
