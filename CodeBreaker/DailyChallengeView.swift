import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var started = false
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var displayDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    private var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: "daily_\(dateString)")
    }

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            if !started {
                preStartView
            }
        }
        .navigationDestination(isPresented: $started) {
            GameView(viewModel: viewModel)
        }
        .navigationTitle("每日挑战")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var preStartView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.warning)
            }

            Text(displayDate)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("每日挑战")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.warning)

            VStack(spacing: 8) {
                ruleRow("密码长度", "4 位")
                ruleRow("可用颜色", "6 种")
                ruleRow("最大尝试", "7 次")
                ruleRow("允许重复", "否")
            }
            .padding(20)
            .glassCard(cornerRadius: 16)

            if isCompleted {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.accent)
                    Text("今日挑战已完成")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text("明天再来挑战新密码！")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 8)
            }

            Spacer()

            if !isCompleted {
                Button {
                    startDailyChallenge()
                } label: {
                    Text("开始挑战")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.bgDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.warning, in: RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Button { dismiss() } label: {
                    Text("返回首页")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .glassCard(cornerRadius: 14)
                }
            }
        }
        .padding(24)
    }

    private func ruleRow(_ label: String, _ value: String) -> some View {
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

    private func startDailyChallenge() {
        let seed = dateString.hashValue
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))

        let colors = Array(PegColor.allCases.prefix(6))
        var pool = colors
        var code: [PegColor] = []
        for _ in 0..<4 {
            let idx = Int(rng.next() % UInt64(pool.count))
            code.append(pool.remove(at: idx))
        }

        viewModel.startDuel(secretCode: code, colorCount: 6, maxAttempts: 7)
        viewModel.mode = .freePlay

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UserDefaults.standard.set(true, forKey: "daily_\(dateString)")
        }

        started = true
    }
}

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
