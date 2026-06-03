import SwiftUI

struct LevelEditorView: View {
    @State private var codeLength = 4
    @State private var colorCount = 6
    @State private var maxAttempts = 8
    @State private var allowDuplicates = false
    @State private var timeLimit = 0
    @State private var startGame = false
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    paramSection("密码长度", value: $codeLength, range: 3...6) { "\($0) 位" }
                    paramSection("颜色数量", value: $colorCount, range: max(codeLength, 4)...8) { "\($0) 种" }
                    paramSection("最大尝试", value: $maxAttempts, range: (codeLength + 1)...15) { "\($0) 次" }

                    toggleSection
                    timeLimitSection
                    difficultyMeter
                    previewColors

                    Spacer(minLength: 20)

                    startButton
                }
                .padding(20)
            }
        }
        .navigationTitle("自定义关卡")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
        .onChange(of: codeLength) { _, newVal in
            if colorCount < newVal { colorCount = newVal }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accent)
            Text("打造你的专属挑战")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.bottom, 8)
    }

    private func paramSection(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, format: (Int) -> String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 8) {
                ForEach(Array(range), id: \.self) { n in
                    Button {
                        withAnimation(.spring(response: 0.2)) { value.wrappedValue = n }
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(value.wrappedValue == n ? AppTheme.bgDark : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(value.wrappedValue == n ? AppTheme.accent : AppTheme.bgCardLight)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var toggleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("允许重复颜色")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("同一颜色可出现多次")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $allowDuplicates)
                .tint(AppTheme.accent)
                .labelsHidden()
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var timeLimitSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("时间限制")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(timeLimit == 0 ? "无" : "\(timeLimit) 秒")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(timeLimit > 0 ? AppTheme.warning : AppTheme.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach([0, 60, 90, 120, 180], id: \.self) { t in
                    Button {
                        withAnimation(.spring(response: 0.2)) { timeLimit = t }
                    } label: {
                        Text(t == 0 ? "无" : "\(t)s")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(timeLimit == t ? AppTheme.bgDark : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(timeLimit == t ? (t > 0 ? AppTheme.warning : AppTheme.accent) : AppTheme.bgCardLight)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var difficultyMeter: some View {
        let score = computeDifficulty()
        let label: String
        let color: Color
        switch score {
        case 0..<30: label = "入门"; color = AppTheme.accent
        case 30..<50: label = "适中"; color = Color(red: 0.2, green: 0.8, blue: 0.4)
        case 50..<70: label = "挑战"; color = AppTheme.warning
        case 70..<85: label = "困难"; color = Color(red: 1.0, green: 0.4, blue: 0.2)
        default: label = "地狱"; color = AppTheme.danger
        }

        return HStack(spacing: 12) {
            Text("难度评估")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.bgCardLight)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100.0)
                }
            }
            .frame(height: 8)

            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 36)
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var previewColors: some View {
        HStack(spacing: 6) {
            Text("可用颜色")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            ForEach(Array(PegColor.allCases.prefix(colorCount))) { color in
                PegView(color: color, size: 24)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var startButton: some View {
        Button {
            let engine = GameEngine(
                codeLength: codeLength,
                colorCount: colorCount,
                allowDuplicates: allowDuplicates,
                maxAttempts: maxAttempts
            )
            viewModel.engine = engine
            viewModel.mode = .freePlay
            viewModel.level = nil

            viewModel.guessHistory = []
            viewModel.currentGuess = Array(repeating: nil, count: codeLength)
            viewModel.phase = .playing
            viewModel.selectedSlot = 0
            viewModel.showSecret = false
            viewModel.shakeGuessRow = false

            if timeLimit > 0 {
                viewModel.timeRemaining = timeLimit
            }

            startGame = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("开始自定义挑战")
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.bgDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func computeDifficulty() -> Int {
        var score = 0.0
        score += Double(codeLength - 3) * 15
        score += Double(colorCount - 4) * 8
        score += max(0, Double(10 - maxAttempts)) * 6
        if allowDuplicates { score += 15 }
        if timeLimit > 0 { score += max(0, Double(180 - timeLimit)) / 3.0 }
        return min(100, Int(score))
    }
}
