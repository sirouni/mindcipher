import SwiftUI

struct LieModeSetupView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var startGame = false
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                header

                VStack(spacing: 8) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        difficultyRow(diff)
                    }
                }
                .padding(12)
                .glassCard()

                infoCard

                Spacer()

                Button {
                    startLieGame()
                    startGame = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                        Text("开始谎言挑战")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.danger, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text("谎言模式")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                Text("系统会骗你一次，识破它！")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var infoCard: some View {
        VStack(spacing: 6) {
            HStack {
                infoChip("\(selectedDifficulty.codeLength)位")
                infoChip("\(selectedDifficulty.colorCount)色")
                infoChip("\(totalAttempts)步")
                infoChip(selectedDifficulty.allowDuplicates ? "可重复" : "不重复")
                Spacer()
                Text("含1次谎言")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
            }

            Label("有1次反馈是假的（差距≤1），猜对时不骗你，结束后揭晓", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .glassCard()
    }

    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.bgCardLight, in: RoundedRectangle(cornerRadius: 6))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.danger)
                Text("规则说明")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                ruleItem("游戏中有且仅有 1 次反馈是假的")
                ruleItem("谎言反馈与真实值接近（差距≤1）")
                ruleItem("猜对时系统不会撒谎")
                ruleItem("游戏结束后会揭示哪步是谎言")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.danger.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.danger.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func ruleItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundStyle(AppTheme.danger)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var totalAttempts: Int {
        let extra: Int
        switch selectedDifficulty {
        case .beginner: extra = 5
        case .easy: extra = 7
        case .medium: extra = 8
        case .hard: extra = 7
        case .expert: extra = 7
        case .master: extra = 5
        }
        return selectedDifficulty.maxAttempts + extra
    }

    private func startLieGame() {
        // 每局随机生成密码，lieMode=true 使引擎进入谎言逻辑
        // 密码自然不会与普通模式重合（都是独立随机生成）
        viewModel.startFreePlay(difficulty: selectedDifficulty, lieMode: true)
    }

    private func difficultyRow(_ diff: Difficulty) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedDifficulty = diff }
        } label: {
            HStack {
                Text(diff.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selectedDifficulty == diff ? .white : AppTheme.textPrimary)
                Spacer()
                Text("\(diff.codeLength)位·\(diff.colorCount)色")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(selectedDifficulty == diff ? .white.opacity(0.7) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDifficulty == diff ? AppTheme.danger : Color.clear)
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
