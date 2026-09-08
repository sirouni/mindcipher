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
            AppTheme.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    paramSection("Code length", value: $codeLength, range: 3...6) { "\($0)" }
                    paramSection("Colors", value: $colorCount, range: max(codeLength, 4)...8) { "\($0)" }
                    paramSection("Max attempts", value: $maxAttempts, range: (codeLength + 1)...15) { "\($0)" }

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
        .navigationTitle(L("editor.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
        .navigationDestination(isPresented: $startGame) {
            GameView(viewModel: viewModel)
        }
        .onChange(of: codeLength) { _, newVal in
            if colorCount < newVal { colorCount = newVal }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            DossierCaption(text: L("menu.editor"))
            Text(L("editor.title"))
                .font(AppFont.display(24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(L("paywall.editor.sub"))
                .font(AppFont.body(13))
                .foregroundStyle(AppTheme.textSecondary)
            Rectangle().fill(AppTheme.ink).frame(height: 1.5).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paramSection(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, format: (Int) -> String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(AppFont.mono(15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            HStack(spacing: 8) {
                ForEach(Array(range), id: \.self) { n in
                    Button {
                        withAnimation(.spring(response: 0.2)) { value.wrappedValue = n }
                    } label: {
                        Text("\(n)")
                            .font(AppFont.display(14, weight: .bold))
                            .foregroundStyle(value.wrappedValue == n ? AppTheme.paper : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(value.wrappedValue == n ? AppTheme.ink : AppTheme.bgCardLight)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .paperCard()
    }

    private var toggleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("editor.dupes"))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L("editor.dupes.desc"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $allowDuplicates)
                .tint(AppTheme.accent)
                .labelsHidden()
        }
        .padding(14)
        .paperCard()
    }

    private var timeLimitSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L("editor.timelimit"))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(timeLimit == 0 ? L("editor.off") : "\(timeLimit)s")
                    .font(AppFont.mono(15, weight: .bold))
                    .foregroundStyle(timeLimit > 0 ? AppTheme.warning : AppTheme.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach([0, 60, 90, 120, 180], id: \.self) { t in
                    Button {
                        withAnimation(.spring(response: 0.2)) { timeLimit = t }
                    } label: {
                        Text(t == 0 ? L("editor.off") : "\(t)s")
                            .font(AppFont.display(12, weight: .bold))
                            .foregroundStyle(timeLimit == t ? AppTheme.paper : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(timeLimit == t ? AppTheme.ink : AppTheme.bgCardLight)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .paperCard()
    }

    private var difficultyMeter: some View {
        let score = computeDifficulty()
        let label: String
        let color: Color
        switch score {
        case 0..<30: label = L("diff.easy"); color = AppTheme.textSecondary
        case 30..<50: label = L("diff.medium"); color = AppTheme.ink
        case 50..<70: label = L("editor.diff.challenge"); color = AppTheme.warning
        case 70..<85: label = L("diff.hard"); color = AppTheme.warning
        default: label = L("editor.diff.hell"); color = AppTheme.danger
        }

        return HStack(spacing: 12) {
            Text(L("editor.difficulty"))
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(14)
        .paperCard()
    }

    private var previewColors: some View {
        HStack(spacing: 6) {
            Text(L("editor.colors"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            ForEach(Array(PegColor.allCases.prefix(colorCount))) { color in
                PegView(color: color, size: 24)
            }
        }
        .padding(14)
        .paperCard()
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
                Text(L("editor.start"))
            }
            .font(AppFont.display(17, weight: .bold))
            .foregroundStyle(AppTheme.paper)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
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
