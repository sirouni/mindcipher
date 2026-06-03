import SwiftUI

struct LieModeSetupView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var startGame = false
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                header

                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        difficultyRow(diff)
                    }
                }
                .padding(16)
                .glassCard()

                infoCard

                rulesCard

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
        VStack(spacing: 8) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.danger)

            Text("谎言模式")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.danger)

            Text("系统会给出一次虚假反馈\n你能识破谎言并破译密码吗？")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var infoCard: some View {
        VStack(spacing: 6) {
            infoRow("密码长度", "\(selectedDifficulty.codeLength) 位")
            infoRow("可用颜色", "\(selectedDifficulty.colorCount) 种")
            infoRow("最大尝试", "\(totalAttempts) 次")
            infoRow("允许重复", selectedDifficulty.allowDuplicates ? "是" : "否")
            infoRow("虚假反馈", "1 次")
        }
        .padding(14)
        .glassCard()
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
