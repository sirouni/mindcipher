import SwiftUI

struct LieLevelSelectView: View {
    let levelManager = LevelManager.shared
    @ObservedObject var progress = ProgressManager.lieShared
    @State private var selectedTier = 0
    @State private var startGame = false
    @State private var previewLevel: Level?
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                lieHeader
                allLevelsGrid
            }

            if let level = previewLevel {
                levelPreviewOverlay(level)
            }
        }
        .navigationTitle(L("lie.task"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    private var lieHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.danger)
            Text("每关含1次虚假反馈")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.danger)
            Spacer()
            Text("\(progress.completedLevels.count)/120")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.danger.opacity(0.08))
    }

    private var allLevelsGrid: some View {
        ScrollView {
            lieLevelPath
                .padding(16)
        }
    }

    private var lieLevelPath: some View {
        let cols = 5
        let rows = (levelManager.levels.count + cols - 1) / cols
        return VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                let isReversed = row % 2 == 1
                HStack(spacing: 4) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = isReversed ? row * cols + (cols - 1 - col) : row * cols + col
                        if idx < levelManager.levels.count {
                            levelCell(levelManager.levels[idx])
                        } else {
                            Color.clear.frame(width: 60, height: 60)
                        }
                    }
                }
                if row < rows - 1 {
                    let connIdx = isReversed ? row * cols : (row + 1) * cols - 1
                    let connected = connIdx < levelManager.levels.count && progress.completedLevels.contains(levelManager.levels[connIdx].id)
                    HStack {
                        if !isReversed { Spacer() }
                        Rectangle()
                            .fill(connected ? AppTheme.danger.opacity(0.4) : AppTheme.textMuted.opacity(0.15))
                            .frame(width: 2, height: 16)
                        if isReversed { Spacer() }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }

    private func levelCell(_ level: Level) -> some View {
        let isCompleted = progress.completedLevels.contains(level.id)
        let isUnlocked = progress.isUnlocked(level: level.id)
        let stars = progress.starsByLevel[level.id] ?? 0

        return Button {
            guard isUnlocked else { return }
            withAnimation(.spring(response: 0.3)) { previewLevel = level }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            isCompleted ? AppTheme.danger :
                            isUnlocked ? AppTheme.bgCardLight :
                            AppTheme.bgCard.opacity(0.4)
                        )
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().stroke(
                                isCompleted ? AppTheme.danger.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                        )

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textMuted)
                    } else {
                        Text("\(level.id)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(isCompleted ? .white : AppTheme.textPrimary)
                    }
                }

                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 7))
                            .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(isUnlocked ? 1.0 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
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
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.3)) { previewLevel = nil } }

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .foregroundStyle(AppTheme.danger)
                    Text("谎言关卡 \(level.id)")
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
                    previewRow("密码长度", "\(level.codeLength) 位")
                    previewRow("可用颜色", "\(level.colorCount) 种")
                    previewRow("最大尝试", "\(totalAttempts) 次")
                    previewRow("允许重复", level.allowDuplicates ? "是" : "否")
                    previewRow("虚假反馈", "1 次")
                }
                .padding(16)
                .glassCard(cornerRadius: 12)

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
                        Text(progress.completedLevels.contains(level.id) ? "重新挑战" : "开始")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(AppTheme.danger, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(28)
            .glassCard(cornerRadius: 20)
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
