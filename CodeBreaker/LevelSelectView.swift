import SwiftUI

struct LevelSelectView: View {
    let levelManager = LevelManager.shared
    @ObservedObject var progress = ProgressManager.shared
    @State private var selectedTier = 0
    @State private var startGame = false
    @State private var selectedLevel: Level?
    @State private var previewLevel: Level?
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                tierSelector
                levelGrid
            }

            if let level = previewLevel {
                levelPreviewOverlay(level)
            }
        }
        .navigationTitle("任务模式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    private func levelPreviewOverlay(_ level: Level) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.3)) { previewLevel = nil } }

            VStack(spacing: 16) {
                Text("关卡 \(level.id)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(level.difficulty.rawValue)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.15), in: Capsule())

                VStack(spacing: 6) {
                    previewRow("密码长度", "\(level.codeLength) 位")
                    previewRow("可用颜色", "\(level.colorCount) 种")
                    previewRow("最大尝试", "\(level.maxAttempts) 次")
                    previewRow("允许重复", level.allowDuplicates ? "是" : "否")
                    if level.timeLimitSeconds > 0 {
                        previewRow("时间限制", "\(level.timeLimitSeconds) 秒")
                    }
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
                    viewModel.startGame(level: level)
                    previewLevel = nil
                    startGame = true
                } label: {
                    Text(progress.completedLevels.contains(level.id) ? "重新挑战" : "开始")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.bgDark)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
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

    private var tierSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<levelManager.tiers.count, id: \.self) { i in
                    tierTab(index: i)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func tierTab(index: Int) -> some View {
        let tier = levelManager.tiers[index]
        let firstLevel = tier.first!
        let completedCount = tier.filter { progress.completedLevels.contains($0.id) }.count

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedTier = index }
        } label: {
            VStack(spacing: 4) {
                Text(firstLevel.tierName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedTier == index ? AppTheme.bgDark : AppTheme.textPrimary)
                Text("\(completedCount)/\(tier.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(selectedTier == index ? AppTheme.bgDark.opacity(0.7) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTier == index ? AppTheme.accent : AppTheme.bgCard)
            )
        }
        .buttonStyle(.plain)
    }

    private var levelGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                if selectedTier < levelManager.tiers.count {
                    ForEach(levelManager.tiers[selectedTier]) { level in
                        levelCell(level)
                    }
                }
            }
            .padding(16)
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
            VStack(spacing: 6) {
                ZStack {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textMuted)
                    } else {
                        Text("\(level.id)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(isCompleted ? AppTheme.accent : AppTheme.textPrimary)
                    }
                }
                .frame(height: 28)

                if isCompleted {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted)
                        }
                    }
                } else {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Image(systemName: "star")
                                .font(.system(size: 8))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isCompleted ? AppTheme.accent.opacity(0.1) :
                        isUnlocked ? AppTheme.bgCard :
                        AppTheme.bgCard.opacity(0.4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isCompleted ? AppTheme.accent.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
