import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResult = false
    @State private var confettiParticles: [ConfettiParticle] = []
    
    @State private var showShareSheet = false
    @State private var revealedSecretCount = 0
    @State private var secretGlow = false
    @ObservedObject private var achievementManager = AchievementManager.shared
    @State private var achievementToast: Achievement?

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                feedbackLegend
                Divider().overlay(AppTheme.textMuted.opacity(0.3)).padding(.horizontal)
                guessBoard
                Spacer(minLength: 8)
                VStack(spacing: 0) {
                    currentGuessRow
                    colorPicker
                    actionBar
                }
                .padding(.top, 6)
                .background(
                    Color.white.opacity(0.4)
                        .ignoresSafeArea(edges: .bottom)
                )
                .overlay(alignment: .top) {
                    Divider().overlay(Color.black.opacity(0.08))
                }
            }

            if showResult { resultOverlay }

            ForEach(confettiParticles) { p in
                ConfettiPiece(particle: p)
            }

            if let toast = achievementToast {
                achievementBanner(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.phase) { _, phase in
            if phase != .playing {
                revealSecretSequentially()
                if case .won(let attempts) = phase {
                    SoundManager.shared.playWin()
                    spawnConfetti()
                    achievementManager.markSpeedAchievement(attempts: attempts)
                } else {
                    SoundManager.shared.playLose()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    achievementManager.checkAll()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(viewModel.codeLength) * 0.2 + 0.6) {
                    withAnimation(.spring(response: 0.5)) { showResult = true }
                }
            }
        }
        .onChange(of: achievementManager.newlyUnlocked?.id) { _, newId in
            guard newId != nil, let a = achievementManager.newlyUnlocked else { return }
            withAnimation(.spring(response: 0.4)) { achievementToast = a }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) { achievementToast = nil }
            }
        }
        
    }

    private func achievementBanner(_ a: Achievement) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: a.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.warning)
                    Text(a.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: AppTheme.warning.opacity(0.3), radius: 12, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                if let level = viewModel.level {
                    Text("Level \(level.id)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(level.difficulty.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                } else if viewModel.mode == .duel {
                    Text("Duel Mode")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                } else {
                    Text("Free Play")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    if viewModel.engine?.lieMode == true {
                        Label("Lie Mode", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.danger)
                    }
                }
            }

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 40, height: 40)
                        .glassCard(cornerRadius: 10)
                }
                .accessibilityLabel("Back")

                Spacer()

                HStack(spacing: 8) {
                    if viewModel.timeRemaining > 0 {
                        timerBadge
                    }
                    attemptsBadge
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var timerBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 11))
            Text("\(viewModel.timeRemaining)s")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(viewModel.timeRemaining <= 15 ? AppTheme.danger : AppTheme.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 8)
    }

    private var attemptsBadge: some View {
        HStack(spacing: 4) {
            Text("\(viewModel.attemptsLeft)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.attemptsLeft <= 2 ? AppTheme.danger : AppTheme.accent)
            Text("left")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 8)
    }

    // MARK: - Feedback Legend

    private var feedbackLegend: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendLine(color: AppTheme.accent, hollow: false, text: "= One right color in the right position")
            legendLine(color: AppTheme.warning, hollow: false, text: "= One right color but in the wrong position")
            legendLine(color: AppTheme.textMuted, hollow: true, text: "= One color is not in the secret code")
            if viewModel.engine?.lieMode == true {
                Text("Lie Mode — one feedback may be fake!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func legendLine(color: Color, hollow: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            if hollow {
                Circle().stroke(color, lineWidth: 1.5).frame(width: 11, height: 11)
            } else {
                Circle().fill(color).frame(width: 11, height: 11)
            }
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Secret Code

    private var secretCodeBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<viewModel.codeLength, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 36, height: 36)

                        if viewModel.showSecret && i < revealedSecretCount {
                            PegView(color: viewModel.secretCode[i], size: 24)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        } else {
                            Image(systemName: "questionmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
            .shadow(
                color: secretGlow ? AppTheme.accent.opacity(0.6) : .clear,
                radius: secretGlow ? 12 : 0
            )
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: secretGlow)

            Spacer()

            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Guess Board

    private let rowHeight: CGFloat = 52

    private var guessBoard: some View {
        let totalRows = viewModel.maxAttempts

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<totalRows, id: \.self) { i in
                        let hasGuess = i < viewModel.guessHistory.count

                        if hasGuess {
                            let record = viewModel.guessHistory[i]
                            GuessRowView(
                                index: i + 1,
                                guess: record.guess,
                                feedback: record.feedback,
                                codeLength: viewModel.codeLength,
                                gameOver: viewModel.phase != .playing
                            )
                            .frame(minHeight: rowHeight)
                            .id(record.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        } else {
                            HStack {
                                Text("\(i + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(white: 0.78))
                                    .frame(width: 20)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .frame(height: rowHeight)
                        }

                        Divider()
                            .overlay(Color(white: 0.86))
                            .padding(.leading, 40)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.guessHistory.count) { _, _ in
                if let last = viewModel.guessHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.75))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 8)
    }

    

    // MARK: - Current Guess Row

    private var slotSize: CGFloat {
        viewModel.codeLength <= 4 ? 52 : viewModel.codeLength <= 5 ? 46 : 40
    }

    private var pegSize: CGFloat {
        viewModel.codeLength <= 4 ? 34 : viewModel.codeLength <= 5 ? 30 : 26
    }

    private var currentGuessRow: some View {
        HStack(spacing: viewModel.codeLength <= 4 ? 10 : 6) {
            ForEach(0..<viewModel.codeLength, id: \.self) { i in
                currentSlot(index: i)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .modifier(ShakeModifier(trigger: viewModel.shakeGuessRow))
    }

    private func currentSlot(index: Int) -> some View {
        let isSelected = index == viewModel.selectedSlot && viewModel.phase == .playing
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.white : Color.white.opacity(0.7))
                .frame(width: slotSize, height: slotSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? AppTheme.accent : Color.black.opacity(0.08),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(color: isSelected ? AppTheme.accent.opacity(0.15) : .clear, radius: 6)

            if let color = viewModel.currentGuess[index] {
                PegView(color: color, size: pegSize)
                    .transition(.scale.combined(with: .opacity))
            } else if isSelected {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: pegSize, height: pegSize)
            }

            if isSelected {
                VStack {
                    Spacer()
                    Triangle()
                        .fill(AppTheme.accent)
                        .frame(width: 8, height: 5)
                        .offset(y: 3)
                }
                .frame(width: slotSize, height: slotSize)
            }
        }
        .onTapGesture {
            SoundManager.shared.playTap()
            if viewModel.currentGuess[index] != nil {
                viewModel.clearSlot(index)
            } else {
                viewModel.tapSlot(index)
            }
        }
        .accessibilityLabel("Slot \(index + 1)")
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        let colorSize: CGFloat = viewModel.availableColors.count <= 6 ? 42 : 36
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableColors) { color in
                    colorButton(color, size: colorSize)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func colorButton(_ color: PegColor, size: CGFloat) -> some View {
        Button {
            SoundManager.shared.playPlace()
            viewModel.selectColor(color)
        } label: {
            PegView(color: color, size: size)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .disabled(viewModel.phase != .playing)
        .accessibilityLabel(color.displayName)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                SoundManager.shared.playTap()
                for i in 0..<viewModel.codeLength {
                    viewModel.clearSlot(i)
                }
                viewModel.selectedSlot = 0
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 50, height: 50)
                    .glassCard(cornerRadius: 12)
            }
            .disabled(viewModel.phase != .playing)

            Button {
                SoundManager.shared.playSubmit()
                viewModel.submitGuess()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                    Text(L("game.submit"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(viewModel.canSubmit ? Color.white : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canSubmit ? AppTheme.accent : Color(white: 0.88))
                )
            }
            .disabled(!viewModel.canSubmit)

            Button { shareImage() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 50, height: 50)
                    .glassCard(cornerRadius: 12)
            }
            .accessibilityLabel("Share")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 20) {
                if case .won(let attempts) = viewModel.phase {
                    winContent(attempts: attempts)
                } else {
                    loseContent
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 4)
            )
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    private func winContent(attempts: Int) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppTheme.accent.opacity(0.05))
                    .frame(width: 130, height: 130)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)
                    .shadow(color: AppTheme.accent.opacity(0.5), radius: 20)
            }

            Text(L("result.win"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(L("result.win.steps", attempts))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            starsDisplay(attempts: attempts)

            revealedCodeRow

            resultButtons
        }
    }

    private var loseContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.danger)
                .shadow(color: AppTheme.danger.opacity(0.5), radius: 20)

            Text(L("result.lose"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(L("result.lose.desc"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            revealedCodeRow

            resultButtons
        }
    }

    private var revealedCodeRow: some View {
        HStack(spacing: 8) {
            Text(L("result.code"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            ForEach(0..<viewModel.secretCode.count, id: \.self) { i in
                PegView(color: viewModel.secretCode[i], size: 28)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .glassCard(cornerRadius: 10)
    }

    @ViewBuilder
    private var lieRevealSection: some View {
        if viewModel.engine?.lieMode == true {
            if let lieGuess = viewModel.engine?.lieAtGuess, lieGuess <= viewModel.guessHistory.count {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.danger)
                        Text("Step \(lieGuess) was a lie!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.danger)
                    }

                    let record = viewModel.guessHistory[lieGuess - 1]
                    let realFeedback = viewModel.engine!.computeRealFeedback(guess: record.guess)
                    HStack(spacing: 4) {
                        Text("Fake:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                        Text("\(record.feedback.exact) exact \(record.feedback.partial) partial")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.danger)
                        Text("→ Real:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                        Text("\(realFeedback.exact) exact \(realFeedback.partial) partial")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.danger.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.danger.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.accent)
                    Text("No lie triggered (you won too fast!)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    private func starsDisplay(attempts: Int) -> some View {
        let ratio = Double(attempts) / Double(viewModel.maxAttempts)
        let stars = ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
        return HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: 28))
                    .foregroundStyle(i < stars ? AppTheme.warning : AppTheme.textMuted)
                    .scaleEffect(i < stars ? 1.0 : 0.85)
            }
        }
    }

    private var resultButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    shareImage()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Share")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accent, lineWidth: 1.5)
                    )
                }

                if let level = viewModel.level {
                    if case .won = viewModel.phase,
                       let next = LevelManager.shared.level(for: level.id + 1) {
                        Button {
                            showResult = false
                            confettiParticles = []
                            viewModel.startGame(level: next)
                        } label: {
                            Text("Next →")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Button {
                            showResult = false
                            confettiParticles = []
                            viewModel.startGame(level: level)
                        } label: {
                            Text("Retry")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else {
                    Button {
                        showResult = false
                        confettiParticles = []
                        let wasLie = viewModel.engine?.lieMode ?? false
                        viewModel.startFreePlay(difficulty: viewModel.lastDifficulty, lieMode: wasLie)
                    } label: {
                        Text("Play Again")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Button {
                confettiParticles = []
                dismiss()
            } label: {
                Text("Back")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    private func shareImage() {
        let isLie = viewModel.engine?.lieMode ?? false
        let lieAt = viewModel.engine?.lieAtGuess

        let won: Bool
        let attempts: Int
        let isPlaying: Bool
        switch viewModel.phase {
        case .won(let a): won = true; attempts = a; isPlaying = false
        case .lost: won = false; attempts = viewModel.guessHistory.count; isPlaying = false
        case .playing: won = false; attempts = viewModel.guessHistory.count; isPlaying = true
        }

        let rows: [ShareRowData] = viewModel.guessHistory.enumerated().map { idx, record in
            ShareRowData(
                id: idx + 1,
                guess: record.guess,
                feedback: record.feedback,
                isLie: !isPlaying && isLie && lieAt == idx + 1
            )
        }

        var lieFake: Feedback?
        var lieReal: Feedback?
        if !isPlaying, isLie, let step = lieAt, step <= viewModel.guessHistory.count {
            lieFake = viewModel.guessHistory[step - 1].feedback
            lieReal = viewModel.engine?.computeRealFeedback(guess: viewModel.guessHistory[step - 1].guess)
        }

        let card = ShareCardView(
            rows: rows,
            codeLength: viewModel.codeLength,
            maxAttempts: viewModel.maxAttempts,
            colorCount: viewModel.availableColors.count,
            won: won,
            attempts: attempts,
            levelId: viewModel.level?.id,
            difficultyName: viewModel.lastDifficulty.rawValue,
            isLieMode: isLie,
            lieStep: lieAt,
            lieFakeFeedback: lieFake,
            lieRealFeedback: lieReal,
            isPlaying: isPlaying,
            availableColors: viewModel.availableColors
        )

        let renderer = ImageRenderer(content: card.frame(width: 390))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }

        let text = viewModel.generateShareText()
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = root.view
        root.present(vc, animated: true)
    }

    // MARK: - Confetti

    private func revealSecretSequentially() {
        revealedSecretCount = 0
        secretGlow = false
        for i in 0..<viewModel.codeLength {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    revealedSecretCount = i + 1
                }
                SoundManager.shared.playTap()
            }
        }
        if case .won = viewModel.phase {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(viewModel.codeLength) * 0.2 + 0.2) {
                secretGlow = true
            }
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange, .cyan, .pink]
        var particles: [ConfettiParticle] = []
        for _ in 0..<40 {
            particles.append(ConfettiParticle(
                x: CGFloat.random(in: 20...380),
                y: CGFloat.random(in: -50...(-10)),
                targetY: CGFloat.random(in: 600...900),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                delay: Double.random(in: 0...0.5)
            ))
        }
        confettiParticles = particles
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let rotation: Double
    let size: CGFloat
    let color: Color
    let delay: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var fallen = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(fallen ? particle.rotation + 360 : particle.rotation))
            .position(
                x: particle.x + (fallen ? CGFloat.random(in: -30...30) : 0),
                y: fallen ? particle.targetY : particle.y
            )
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 2.0).delay(particle.delay)) {
                    fallen = true
                }
            }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Guess Row (History)

struct GuessRowView: View {
    let index: Int
    let guess: [PegColor]
    let feedback: Feedback
    let codeLength: Int
    var gameOver: Bool = false
    @State private var revealed = false

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20)

            HStack(spacing: 6) {
                ForEach(0..<guess.count, id: \.self) { i in
                    PegView(color: guess[i], size: 32)
                        .scaleEffect(revealed ? 1.0 : 0.5)
                        .opacity(revealed ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.6)
                                .delay(Double(i) * 0.08),
                            value: revealed
                        )
                }
            }

            Spacer()

            feedbackDots
                .opacity(revealed ? 1.0 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.4), value: revealed)

            if gameOver && feedback.isLie {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            gameOver && feedback.isLie ? AppTheme.danger.opacity(0.7) : Color.black.opacity(0.06),
                            lineWidth: gameOver && feedback.isLie ? 2 : 1
                        )
                )
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Row \(index) \(guess.map { $0.displayName }.joined(separator: " ")) feedback \(feedbackLabel)")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                revealed = true
            }
        }
    }

    private var feedbackLabel: String {
        "\(feedback.exact) exact \(feedback.partial) partial \(codeLength - feedback.exact - feedback.partial) empty"
    }

    private var feedbackDots: some View {
        let exact = feedback.exact
        let partial = feedback.partial
        let empty = codeLength - exact - partial

        return HStack(spacing: 3) {
            ForEach(0..<exact, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 10, height: 10)
            }
            ForEach(0..<partial, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.warning)
                    .frame(width: 10, height: 10)
            }
            ForEach(0..<empty, id: \.self) { _ in
                Circle()
                    .stroke(Color(white: 0.75), lineWidth: 1)
                    .frame(width: 10, height: 10)
            }
        }
    }
}

// MARK: - Shake Modifier

struct ShakeModifier: ViewModifier {
    var trigger: Bool
    @State private var shakeOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                guard newValue else { return }
                SoundManager.shared.playError()
                withAnimation(.interactiveSpring(response: 0.05, dampingFraction: 0.2)) {
                    shakeOffset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.interactiveSpring(response: 0.05, dampingFraction: 0.2)) {
                        shakeOffset = -8
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.interactiveSpring(response: 0.05, dampingFraction: 0.3)) {
                        shakeOffset = 5
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                        shakeOffset = 0
                    }
                }
            }
    }
}

// MARK: - Share Card

struct ShareRowData: Identifiable {
    let id: Int
    let guess: [PegColor]
    let feedback: Feedback
    let isLie: Bool
}

struct ShareCardView: View {
    let rows: [ShareRowData]
    let codeLength: Int
    let maxAttempts: Int
    let colorCount: Int
    let won: Bool
    let attempts: Int
    let levelId: Int?
    let difficultyName: String
    let isLieMode: Bool
    let lieStep: Int?
    let lieFakeFeedback: Feedback?
    let lieRealFeedback: Feedback?
    let isPlaying: Bool
    let availableColors: [PegColor]

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let danger = Color(red: 0.85, green: 0.20, blue: 0.20)
    private let bgLight = Color(red: 0.92, green: 0.95, blue: 0.98)

    private var stars: Int {
        guard won else { return 0 }
        let ratio = Double(attempts) / Double(maxAttempts)
        return ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            shareTopBar
            shareFeedbackLegend
            Divider().overlay(Color(white: 0.82)).padding(.horizontal)
            shareGuessBoard
            shareColorInfo
            shareInfoBar
        }
        .background(bgLight)
    }

    // MARK: - Top Bar

    private var shareTopBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(white: 0.55))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.55))
                )

            Spacer()

            VStack(spacing: 2) {
                if let lid = levelId {
                    Text("Level \(lid)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.12))
                    Text(difficultyName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                } else {
                    Text("Free Play")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.12))
                }
                if isLieMode {
                    Text("Lie Mode")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(danger)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(maxAttempts - rows.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                Text("left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.55))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Legend

    private var shareFeedbackLegend: some View {
        VStack(alignment: .leading, spacing: 3) {
            shareLegendLine(color: accent, hollow: false, text: "= One right color in the right position")
            shareLegendLine(color: warning, hollow: false, text: "= One right color but in the wrong position")
            shareLegendLine(color: Color(white: 0.65), hollow: true, text: "= One color is not in the secret code")
            if isLieMode {
                Text("Lie Mode — one feedback may be fake!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(danger)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func shareLegendLine(color: Color, hollow: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            if hollow {
                Circle().stroke(color, lineWidth: 1.5).frame(width: 11, height: 11)
            } else {
                Circle().fill(color).frame(width: 11, height: 11)
            }
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(white: 0.4))
        }
    }

    // MARK: - Guess Board (only filled rows)

    private var shareGuessBoard: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                shareGuessRow(row)
                Divider().padding(.leading, 40)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.75))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func shareGuessRow(_ row: ShareRowData) -> some View {
        HStack(spacing: 10) {
            Text("\(row.id)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .frame(width: 20)

            HStack(spacing: 6) {
                ForEach(Array(row.guess.enumerated()), id: \.offset) { _, peg in
                    Circle()
                        .fill(pegGrad(peg))
                        .frame(width: 32, height: 32)
                        .shadow(color: pegCol(peg).opacity(0.2), radius: 2, y: 1)
                }
            }

            Spacer()

            feedbackDots(row.feedback)

            if row.isLie {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(danger)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(row.isLie ? danger.opacity(0.06) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(row.isLie ? danger.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func feedbackDots(_ fb: Feedback) -> some View {
        let dots: [(Color, Bool)] =
            Array(repeating: (accent, false), count: fb.exact) +
            Array(repeating: (warning, false), count: fb.partial) +
            Array(repeating: (Color(white: 0.65), true), count: max(0, codeLength - fb.exact - fb.partial))

        return HStack(spacing: 3) {
            ForEach(Array(dots.enumerated()), id: \.offset) { _, d in
                if d.1 {
                    Circle().stroke(d.0, lineWidth: 1).frame(width: 10, height: 10)
                } else {
                    Circle().fill(d.0).frame(width: 10, height: 10)
                }
            }
        }
    }

    // MARK: - Input Area (mirrors game bottom)

    private var shareColorInfo: some View {
        let slotSize: CGFloat = codeLength <= 4 ? 52 : codeLength <= 5 ? 46 : 40
        let slotSpacing: CGFloat = codeLength <= 4 ? 10 : 6
        let colorSize: CGFloat = availableColors.count <= 6 ? 42 : 36

        return VStack(spacing: 8) {
            shareSlotsRow(slotSize: slotSize, spacing: slotSpacing)
            shareColorsRow(colorSize: colorSize)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func shareSlotsRow(slotSize: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<codeLength, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: slotSize, height: slotSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func shareColorsRow(colorSize: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(availableColors.enumerated()), id: \.offset) { _, peg in
                Circle()
                    .fill(pegGrad(peg))
                    .frame(width: colorSize, height: colorSize)
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Info Bar (result + lie reveal)

    private var shareInfoBar: some View {
        VStack(spacing: 4) {
            if isPlaying {
                Text("In Progress — \(rows.count)/\(maxAttempts)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.4))
            } else if won {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundStyle(i < stars ? warning : Color(white: 0.75))
                    }
                }
                Text("Solved in \(attempts)/\(maxAttempts) steps")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            } else {
                Text("Failed — \(rows.count)/\(maxAttempts)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(danger)
            }

            if isLieMode, let step = lieStep, let fakeFb = lieFakeFeedback, let realFb = lieRealFeedback {
                HStack(spacing: 6) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 12))
                    Text("Step \(step) was a lie!  Fake: \(fakeFb.exact)E \(fakeFb.partial)P → Real: \(realFb.exact)E \(realFb.partial)P")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(danger)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legend

    // MARK: - Peg Colors

    private func pegCol(_ peg: PegColor) -> Color {
        switch peg {
        case .red: return Color(red: 0.95, green: 0.25, blue: 0.25)
        case .green: return Color(red: 0.2, green: 0.85, blue: 0.35)
        case .blue: return Color(red: 0.25, green: 0.45, blue: 0.95)
        case .yellow: return Color(red: 0.95, green: 0.85, blue: 0.15)
        case .purple: return Color(red: 0.65, green: 0.3, blue: 0.9)
        case .orange: return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .cyan: return Color(red: 0.1, green: 0.85, blue: 0.9)
        case .pink: return Color(red: 0.95, green: 0.4, blue: 0.65)
        }
    }

    private func pegGrad(_ peg: PegColor) -> LinearGradient {
        let c = pegCol(peg)
        return LinearGradient(colors: [c.opacity(0.85), c, c.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
