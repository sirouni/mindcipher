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
                progressBar
                allLevelsGrid
            }

            if let level = previewLevel {
                levelPreviewOverlay(level)
            }
        }
        .navigationTitle(L("menu.classic"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    private var progressBar: some View {
        HStack {
            Text("\(progress.completedLevels.count)/120")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.accent)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.bgCardLight)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.accent)
                        .frame(width: geo.size.width * CGFloat(progress.completedLevels.count) / 120.0)
                }
            }
            .frame(height: 6)
            Text("⭐\(progress.totalStars)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.warning)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var allLevelsGrid: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(levelManager.tiers.indices, id: \.self) { tierIdx in
                    let tier = levelManager.tiers[tierIdx]
                    let tierName = tier.first?.tierName ?? ""
                    let diffName = tier.first?.difficulty.rawValue ?? ""
                    let completedCount = tier.filter { progress.completedLevels.contains($0.id) }.count

                    tierHeader(title: diffName, subtitle: tierName, done: completedCount, total: tier.count, color: AppTheme.accent)
                    tierGrid(levels: tier, color: AppTheme.accent)

                    if tierIdx < levelManager.tiers.count - 1 {
                        Rectangle()
                            .fill(completedCount == tier.count ? AppTheme.accent.opacity(0.4) : AppTheme.textMuted.opacity(0.1))
                            .frame(width: 3, height: 24)
                    }
                }
            }
            .padding(12)
        }
    }

    private func tierHeader(title: String, subtitle: String, done: Int, total: Int, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text("\(done)/\(total)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(done == total ? color : AppTheme.textMuted)
        }
        .padding(.horizontal, 4)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func tierGrid(levels: [Level], color: Color) -> some View {
        let cols = 5
        let rows = (levels.count + cols - 1) / cols

        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                let isReversed = row % 2 == 1
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = isReversed ? row * cols + (cols - 1 - col) : row * cols + col
                        if idx < levels.count {
                            levelCell(levels[idx])
                        } else {
                            Color.clear.frame(width: 56, height: 56)
                        }
                        if col < cols - 1 {
                            let curIdx = isReversed ? row * cols + (cols - 1 - col) : row * cols + col
                            let nextIdx = isReversed ? row * cols + (cols - 2 - col) : row * cols + col + 1
                            let linked = curIdx < levels.count && nextIdx < levels.count &&
                                progress.completedLevels.contains(levels[min(curIdx, nextIdx)].id)
                            Rectangle()
                                .fill(linked ? color.opacity(0.5) : AppTheme.textMuted.opacity(0.12))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                if row < rows - 1 {
                    let turnIdx = isReversed ? row * cols : (row + 1) * cols - 1
                    let linked = turnIdx < levels.count && progress.completedLevels.contains(levels[turnIdx].id)
                    HStack {
                        if !isReversed { Spacer() }
                        Rectangle()
                            .fill(linked ? color.opacity(0.5) : AppTheme.textMuted.opacity(0.12))
                            .frame(width: 3, height: 22)
                        if isReversed { Spacer() }
                    }
                    .padding(.horizontal, 26)
                }
            }
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

    private func levelCell(_ level: Level) -> some View {
        let isCompleted = progress.completedLevels.contains(level.id)
        let isUnlocked = progress.isUnlocked(level: level.id)
        let stars = progress.starsByLevel[level.id] ?? 0
        let isNext = !isCompleted && isUnlocked

        return Button {
            guard isUnlocked else { return }
            withAnimation(.spring(response: 0.3)) { previewLevel = level }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isCompleted ? AppTheme.accent.opacity(0.25) :
                        isNext ? AppTheme.accent.opacity(0.15) :
                        AppTheme.bgCard.opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isNext ? AppTheme.accent : 
                                isCompleted ? AppTheme.accent.opacity(0.4) :
                                AppTheme.textMuted.opacity(0.1),
                                lineWidth: isNext ? 2 : 1
                            )
                    )

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted.opacity(0.4))
                } else {
                    VStack(spacing: 3) {
                        Text("\(level.id)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(isCompleted ? AppTheme.accent : AppTheme.textPrimary)
                        if isCompleted {
                            HStack(spacing: 1) {
                                ForEach(0..<3, id: \.self) { i in
                                    Image(systemName: i < stars ? "star.fill" : "star")
                                        .font(.system(size: 7))
                                        .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted.opacity(0.4))
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 56, height: 56)
            .opacity(isUnlocked ? 1.0 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
