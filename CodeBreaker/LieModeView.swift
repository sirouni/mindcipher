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
                        Text("Start Lie Challenge")
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
                Text("Lie Mode")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                Text("The system lies once. Spot it!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var infoCard: some View {
        VStack(spacing: 6) {
            HStack {
                infoChip("\(selectedDifficulty.codeLength)L")
                infoChip("\(selectedDifficulty.colorCount)C")
                infoChip("\(totalAttempts)T")
                infoChip(selectedDifficulty.allowDuplicates ? "Repeats" : "No Repeats")
                Spacer()
                Text("+1 Lie")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
            }

            Label("1 feedback is fake (diff≤1), no lie on correct guess, revealed at end", systemImage: "exclamationmark.triangle.fill")
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
                Text("Rules")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                ruleItem("Exactly 1 feedback is fake")
                ruleItem("Fake feedback is close to real (diff≤1)")
                ruleItem("No lie when you guess correctly")
                ruleItem("Reveals which step was a lie after the game")
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
                Text("\(diff.codeLength)×\(diff.colorCount)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(selectedDifficulty == diff ? .white.opacity(0.7) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
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
