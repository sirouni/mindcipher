import SwiftUI
import GameKit
import StoreKit
import CoreImage.CIFilterBuiltins

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    
    @State private var showResult = false
    @State private var confettiParticles: [ConfettiParticle] = []
    
    @State private var showShareSheet = false
    @State private var revealedSecretCount = 0
    @State private var secretGlow = false
    @ObservedObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var hintCoinManager = HintCoinManager.shared
    @State private var achievementToast: Achievement?
    @State private var hintToast: String?
    @State private var lieRevealShowReal = false
    @State private var showLieKickoff = false

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

                ZStack(alignment: .top) {
                    guessBoard

                    if viewModel.showNotes {
                        NotesGridView(viewModel: viewModel)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 6)
                    }
                }

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

            if showLieKickoff,
               viewModel.engine?.lieMode == true,
               viewModel.phase == .playing,
               viewModel.guessHistory.isEmpty {
                lieKickoffBanner
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

            if let hint = hintToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.warning)
                        Text(hint)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    )
                    .padding(.bottom, 160)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(99)
            }
        }
        .navigationBarHidden(true)
        .task(id: viewModel.gameStartTime) {
            guard viewModel.engine?.lieMode == true, viewModel.phase == .playing else {
                showLieKickoff = false
                return
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showLieKickoff = true
            }
            try? await Task.sleep(for: .seconds(2.8))
            withAnimation(.easeOut(duration: 0.35)) {
                showLieKickoff = false
            }
        }
        .onChange(of: viewModel.phase) { _, phase in
            if phase != .playing {
                revealSecretSequentially()
                if case .won(let attempts) = phase {
                    SoundManager.shared.playWin()
                    spawnConfetti()
                    achievementManager.markSpeedAchievement(attempts: attempts)
                    if [3, 15, 50].contains(StatsManager.shared.gamesWon) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            requestReview()
                        }
                    }
                } else {
                    SoundManager.shared.playLose()
                }
                if viewModel.engine?.lieMode == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        SoundManager.shared.playLieReveal()
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    achievementManager.checkAll()
                }
                let overlayDelay = Double(viewModel.codeLength) * 0.2 + 0.6
                    + (viewModel.engine?.lieMode == true ? 0.45 : 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + overlayDelay) {
                    withAnimation(.spring(response: 0.5)) { showResult = true }
                }
            }
        }
        .onChange(of: showResult) { _, shown in
            guard shown, viewModel.engine?.lieMode == true else { return }
            lieRevealShowReal = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    lieRevealShowReal = true
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
        .onChange(of: viewModel.lastHintMessage) { _, msg in
            guard let msg else { return }
            withAnimation(.spring(response: 0.3)) { hintToast = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) { hintToast = nil }
                viewModel.lastHintMessage = nil
            }
        }
        
    }

    private var lieKickoffBanner: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "theatermask.and.paintbrush.fill")
                    .font(.system(size: 18, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating)
                Text(L("lie.kickoff"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppTheme.danger)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: AppTheme.danger.opacity(0.35), radius: 16, y: 6)
            )
            .padding(.top, 100)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(80)
        .allowsHitTesting(false)
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
                    if viewModel.engine?.lieMode == true {
                        Text("\(level.difficulty.rawValue) · \(L("lie.mode"))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.danger)
                    } else {
                        Text(level.difficulty.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                } else if viewModel.mode == .duel {
                    Text(L("game.duel"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                } else if viewModel.mode == .online {
                    Text(L("online.title"))
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
        HStack(spacing: 3) {
            Text("\(viewModel.attemptsLeft)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.attemptsLeft <= 2 ? AppTheme.danger : AppTheme.accent)
            Text("left")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .glassCard(cornerRadius: 8)
        .fixedSize()
    }

    // MARK: - Feedback Legend

    private var feedbackLegend: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendLine(type: .exact, text: "= One right color in the right position")
            legendLine(type: .partial, text: "= One right color but in the wrong position")
            legendLine(type: .miss, text: "= One color is not in the secret code")
            if viewModel.engine?.lieMode == true, !showLieKickoff {
                HStack(spacing: 6) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 12, weight: .bold))
                        .symbolEffect(.pulse)
                    Text(L("lie.clue"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.danger)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func legendLine(type: FeedbackType, text: String) -> some View {
        HStack(spacing: 6) {
            FeedbackDotView(type: type, size: 18)
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
                                gameOver: viewModel.phase != .playing,
                                isLieMode: viewModel.engine?.lieMode == true
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

    private func confirmedColor(for position: Int) -> PegColor? {
        guard position < viewModel.notes.count else { return nil }
        let confirmed = viewModel.availableColors.filter { viewModel.notes[position][$0] == .confirmed }
        return confirmed.count == 1 ? confirmed.first : nil
    }

    private func currentSlot(index: Int) -> some View {
        let isSelected = index == viewModel.selectedSlot && viewModel.phase == .playing
        let hintColor = confirmedColor(for: index)
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
            } else if let hint = hintColor {
                PegView(color: hint, size: pegSize)
                    .opacity(0.35)
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
        let marker = viewModel.noteMarker(position: viewModel.selectedSlot, color: color)
        let isEliminated = marker == .eliminated
        return Button {
            SoundManager.shared.playPlace()
            viewModel.selectColor(color)
        } label: {
            PegView(color: color, size: size)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .overlay {
                    if isEliminated {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                        Image(systemName: "xmark")
                            .font(.system(size: size * 0.35, weight: .bold))
                            .foregroundStyle(AppTheme.danger.opacity(0.8))
                    } else if marker == .confirmed {
                        Circle()
                            .stroke(AppTheme.accent, lineWidth: 2.5)
                            .frame(width: size + 4, height: size + 4)
                    }
                }
        }
        .disabled(viewModel.phase != .playing || isEliminated)
        .accessibilityLabel(color.displayName)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 6) {
            Button {
                SoundManager.shared.playTap()
                for i in 0..<viewModel.codeLength {
                    viewModel.clearSlot(i)
                }
                viewModel.selectedSlot = 0
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 50)
                    .glassCard(cornerRadius: 12)
            }
            .disabled(viewModel.phase != .playing)

            Button {
                SoundManager.shared.playTap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.showNotes.toggle()
                }
            } label: {
                Image(systemName: viewModel.showNotes ? "note.text" : "note.text.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.showNotes ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 44, height: 50)
                    .glassCard(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.showNotes ? AppTheme.accent.opacity(0.4) : .clear, lineWidth: 1.5)
                    )
            }
            .accessibilityLabel("Notes")

            Button {
                SoundManager.shared.playTap()
                viewModel.useHint()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.canUseHint ? AppTheme.warning : AppTheme.textMuted)
                        .frame(width: 44, height: 50)
                        .glassCard(cornerRadius: 12)

                    Text("\(hintCoinManager.coins)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(
                            hintCoinManager.coins > 0 ? AppTheme.warning : Color(white: 0.7),
                            in: Circle()
                        )
                        .offset(x: 2, y: -2)
                }
            }
            .disabled(!viewModel.canUseHint)
            .accessibilityLabel("Hint")

            Button {
                if viewModel.engine?.lieMode == true {
                    SoundManager.shared.playLieSubmit()
                } else {
                    SoundManager.shared.playSubmit()
                }
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 50)
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

            if viewModel.isDailyChallenge {
                dailyScoreBadge(attempts: attempts)
            }

            hintCoinProgress

            revealedCodeRow

            lieRevealSection

            resultButtons
        }
    }

    private func dailyScoreBadge(attempts: Int) -> some View {
        let elapsed = Int(Date().timeIntervalSince(viewModel.gameStartTime ?? Date()))
        let score = (viewModel.maxAttempts - attempts) * 10000 + max(0, 10000 - elapsed)
        return HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.warning)
            Text("Score: \(score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            if GameCenterManager.shared.isAuthenticated {
                Text("Submitted!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 10)
    }

    private var hintCoinProgress: some View {
        let wins = hintCoinManager.winsTowardsCoin
        let needed = HintCoinManager.winsPerCoin

        return HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.warning)

            if hintCoinManager.justEarnedCoin {
                Text("+1 Hint Coin! (\(hintCoinManager.coins) total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warning)
            } else {
                Text("\(wins)/\(needed) wins to next coin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 3) {
                    ForEach(0..<needed, id: \.self) { i in
                        Circle()
                            .fill(i < wins ? AppTheme.warning : AppTheme.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 10)
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

            lieRevealSection

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
                let record = viewModel.guessHistory[lieGuess - 1]
                let realFeedback = viewModel.engine!.computeRealFeedback(guess: record.guess)
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(L("lie.reveal", lieGuess))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.danger)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("lie.fake"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.textMuted)
                            FeedbackDotsRow(
                                feedback: record.feedback,
                                codeLength: viewModel.codeLength,
                                size: 16
                            )
                            .opacity(lieRevealShowReal ? 0.4 : 1)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.top, 12)
                            .opacity(lieRevealShowReal ? 1 : 0.25)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("lie.real.short"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.textMuted)
                            FeedbackDotsRow(
                                feedback: realFeedback,
                                codeLength: viewModel.codeLength,
                                size: 16
                            )
                            .scaleEffect(lieRevealShowReal ? 1 : 0.7)
                            .opacity(lieRevealShowReal ? 1 : 0)
                        }
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
                    Text(L("lie.notrigger"))
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
                            if viewModel.engine?.lieMode == true {
                                let extra = level.difficulty.lieExtraAttempts
                                viewModel.startLieGame(level: next, totalAttempts: next.maxAttempts + extra)
                            } else {
                                viewModel.startGame(level: next)
                            }
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
                            if viewModel.engine?.lieMode == true {
                                let extra = level.difficulty.lieExtraAttempts
                                viewModel.startLieGame(level: level, totalAttempts: level.maxAttempts + extra)
                            } else {
                                viewModel.startGame(level: level)
                            }
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

            if case .won = viewModel.phase {
                Button {
                    shareChallengeLink()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13))
                        Text("Challenge a Friend")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.warning, lineWidth: 1.5)
                    )
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

    private func shareChallengeLink() {
        guard let engine = viewModel.engine else { return }
        let playerName = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.displayName : "Agent"

        let url = ChallengeManager.shared.generateChallengeURL(
            seed: engine.seed,
            codeLength: engine.codeLength,
            colorCount: engine.availableColors.count,
            allowDuplicates: viewModel.lastDifficulty.allowDuplicates,
            maxAttempts: engine.maxAttempts,
            mode: engine.lieMode ? .lie : .classic,
            playerName: playerName
        )

        let text = "I cracked this code — can you?\n\(url.absoluteString)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
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

        let cardView: AnyView
        if viewModel.isDailyChallenge {
            cardView = AnyView(
                DailyShareCardView(
                    rows: rows,
                    codeLength: viewModel.codeLength,
                    maxAttempts: viewModel.maxAttempts,
                    won: won,
                    attempts: attempts,
                    availableColors: viewModel.availableColors
                )
                .frame(width: 390)
            )
        } else {
            var lieFake: Feedback?
            var lieReal: Feedback?
            if !isPlaying, isLie, let step = lieAt, step <= viewModel.guessHistory.count {
                lieFake = viewModel.guessHistory[step - 1].feedback
                lieReal = viewModel.engine?.computeRealFeedback(guess: viewModel.guessHistory[step - 1].guess)
            }

            cardView = AnyView(
                ShareCardView(
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
                .frame(width: 390)
            )
        }

        let renderer = ImageRenderer(content: cardView)
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
    var isLieMode: Bool = false
    @State private var revealed = false
    @State private var glitch = false
    @State private var stampIn = false

    private var pegDisplaySize: CGFloat {
        codeLength <= 4 ? 32 : codeLength <= 5 ? 28 : 24
    }

    private var pegSpacing: CGFloat {
        codeLength <= 4 ? 6 : 4
    }

    private var feedbackDotSize: CGFloat {
        codeLength <= 4 ? 18 : 14
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 16)

            HStack(spacing: pegSpacing) {
                ForEach(0..<guess.count, id: \.self) { i in
                    PegView(color: guess[i], size: pegDisplaySize)
                        .scaleEffect(revealed ? 1.0 : 0.5)
                        .opacity(revealed ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.35, dampingFraction: 0.6)
                                .delay(Double(i) * 0.08),
                            value: revealed
                        )
                }
            }

            Spacer(minLength: 4)

            feedbackDots
                .opacity(revealed ? (glitch ? 0.2 : 1.0) : 0)
                .offset(x: glitch ? 1.5 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.4), value: revealed)
                .animation(.easeInOut(duration: 0.06), value: glitch)

            if gameOver && feedback.isLie {
                Text(L("lie.stamp"))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(AppTheme.danger, in: Capsule())
                    .rotationEffect(.degrees(-9))
                    .scaleEffect(stampIn ? 1 : 1.7)
                    .opacity(stampIn ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(gameOver && feedback.isLie ? AppTheme.danger.opacity(0.08) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            gameOver && feedback.isLie ? AppTheme.danger.opacity(stampIn ? 0.85 : 0.35) : Color.black.opacity(0.06),
                            lineWidth: gameOver && feedback.isLie ? 2 : 1
                        )
                )
                .shadow(
                    color: gameOver && feedback.isLie && stampIn ? AppTheme.danger.opacity(0.22) : .black.opacity(0.03),
                    radius: gameOver && feedback.isLie ? 6 : 2,
                    y: 1
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Row \(index) \(guess.map { $0.displayName }.joined(separator: " ")) feedback \(feedbackLabel)")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                revealed = true
            }
            if isLieMode {
                flickerFeedback()
            }
            if gameOver && feedback.isLie {
                slamLieStamp()
            }
        }
        .onChange(of: gameOver) { _, over in
            if over && feedback.isLie { slamLieStamp() }
        }
    }

    private func flickerFeedback() {
        let beats: [Double] = [0.48, 0.58, 0.68, 0.78]
        for (i, t) in beats.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                glitch = i % 2 == 0
            }
        }
    }

    private func slamLieStamp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.52)) {
                stampIn = true
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
        let size = feedbackDotSize
        let allTypes: [FeedbackType] =
            Array(repeating: .exact, count: exact) +
            Array(repeating: .partial, count: partial) +
            Array(repeating: .miss, count: empty)

        return Group {
            if codeLength <= 4 {
                HStack(spacing: 3) {
                    ForEach(0..<allTypes.count, id: \.self) { i in
                        FeedbackDotView(type: allTypes[i], size: size)
                    }
                }
            } else {
                let columns = Int(ceil(Double(codeLength) / 2.0))
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<columns, id: \.self) { i in
                            FeedbackDotView(type: allTypes[i], size: size)
                        }
                    }
                    HStack(spacing: 2) {
                        ForEach(columns..<allTypes.count, id: \.self) { i in
                            FeedbackDotView(type: allTypes[i], size: size)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Notes Grid View

struct NotesGridView: View {
    @ObservedObject var viewModel: GameViewModel

    private var cellSize: CGFloat {
        let positions = viewModel.codeLength
        let columns = positions + 1
        let availableWidth = UIScreen.main.bounds.width - 44
        let maxCell = availableWidth / CGFloat(columns)
        return min(maxCell, 48).rounded(.down)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 12)
            gridContent
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
        .padding(.horizontal, 12)
    }

    private var header: some View {
        HStack {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text("Notes")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Button {
                SoundManager.shared.playTap()
                viewModel.clearAllNotes()
            } label: {
                Text("Clear")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.94), in: Capsule())
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.showNotes = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(width: 28, height: 28)
                    .background(Color(white: 0.94), in: Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var gridContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: cellSize, height: 28)
                ForEach(0..<viewModel.codeLength, id: \.self) { pos in
                    Button {
                        SoundManager.shared.playTap()
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            viewModel.toggleColumn(position: pos)
                        }
                    } label: {
                        Text("P\(pos + 1)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: cellSize, height: 28)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.phase != .playing)
                }
            }

            ForEach(viewModel.availableColors) { color in
                HStack(spacing: 0) {
                    Button {
                        SoundManager.shared.playTap()
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            viewModel.toggleRow(color: color)
                        }
                    } label: {
                        PegView(color: color, size: cellSize - 6)
                            .frame(width: cellSize, height: cellSize)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.phase != .playing)

                    ForEach(0..<viewModel.codeLength, id: \.self) { pos in
                        noteCell(position: pos, color: color)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    private func noteCell(position: Int, color: PegColor) -> some View {
        let marker = viewModel.noteMarker(position: position, color: color)
        return Button {
            SoundManager.shared.playTap()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                viewModel.toggleNote(position: position, color: color)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(cellBackground(marker))
                    .frame(width: cellSize - 4, height: cellSize - 4)

                switch marker {
                case .eliminated:
                    Image(systemName: "xmark")
                        .font(.system(size: cellSize * 0.38, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                case .confirmed:
                    Image(systemName: "checkmark")
                        .font(.system(size: cellSize * 0.38, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                case nil:
                    EmptyView()
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .disabled(viewModel.phase != .playing)
    }

    private func cellBackground(_ marker: NoteMarker?) -> Color {
        switch marker {
        case .eliminated: return AppTheme.danger.opacity(0.1)
        case .confirmed: return AppTheme.accent.opacity(0.12)
        case nil: return Color(white: 0.96)
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

    private let appStoreURL = "https://apps.apple.com/app/mind-cipher/id6777428188"

    var body: some View {
        VStack(spacing: 0) {
            shareTopBar
            shareFeedbackLegend
            Divider().overlay(Color(white: 0.82)).padding(.horizontal)
            shareGuessBoard
            shareColorInfo
            shareInfoBar
            shareAppLink
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
            shareLegendLine(type: .exact, text: "= One right color in the right position")
            shareLegendLine(type: .partial, text: "= One right color but in the wrong position")
            shareLegendLine(type: .miss, text: "= One color is not in the secret code")
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

    private func shareLegendLine(type: FeedbackType, text: String) -> some View {
        HStack(spacing: 6) {
            FeedbackDotView(type: type, size: 18)
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

    private var sharePegSize: CGFloat {
        codeLength <= 4 ? 32 : codeLength <= 5 ? 28 : 24
    }

    private func shareGuessRow(_ row: ShareRowData) -> some View {
        HStack(spacing: 6) {
            Text("\(row.id)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .frame(width: 16)

            HStack(spacing: codeLength <= 4 ? 6 : 4) {
                ForEach(Array(row.guess.enumerated()), id: \.offset) { _, peg in
                    Circle()
                        .fill(pegGrad(peg))
                        .frame(width: sharePegSize, height: sharePegSize)
                        .shadow(color: pegCol(peg).opacity(0.2), radius: 2, y: 1)
                        .overlay(
                            Text("\(pegNumber(peg))")
                                .font(.system(size: sharePegSize * 0.45, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        )
                }
            }

            Spacer(minLength: 4)

            feedbackDots(row.feedback)

            if row.isLie {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(danger)
            }
        }
        .padding(.horizontal, 10)
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
        let dotSize: CGFloat = codeLength <= 4 ? 18 : 14
        let types: [FeedbackType] =
            Array(repeating: .exact, count: fb.exact) +
            Array(repeating: .partial, count: fb.partial) +
            Array(repeating: .miss, count: max(0, codeLength - fb.exact - fb.partial))

        return Group {
            if codeLength <= 4 {
                HStack(spacing: 3) {
                    ForEach(Array(types.enumerated()), id: \.offset) { _, t in
                        FeedbackDotView(type: t, size: dotSize)
                    }
                }
            } else {
                let columns = Int(ceil(Double(codeLength) / 2.0))
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<columns, id: \.self) { i in
                            FeedbackDotView(type: types[i], size: dotSize)
                        }
                    }
                    HStack(spacing: 2) {
                        ForEach(columns..<types.count, id: \.self) { i in
                            FeedbackDotView(type: types[i], size: dotSize)
                        }
                    }
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
            ForEach(Array(availableColors.enumerated()), id: \.offset) { idx, peg in
                Circle()
                    .fill(pegGrad(peg))
                    .frame(width: colorSize, height: colorSize)
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .overlay(
                        Text("\(idx + 1)")
                            .font(.system(size: colorSize * 0.4, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    )
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
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "theatermask.and.paintbrush.fill")
                            .font(.system(size: 12))
                        Text("Step \(step) was a lie!")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(danger)

                    HStack(spacing: 8) {
                        FeedbackDotsRow(feedback: fakeFb, codeLength: codeLength, size: 14)
                            .opacity(0.45)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(white: 0.55))
                        FeedbackDotsRow(feedback: realFb, codeLength: codeLength, size: 14)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    // MARK: - App Store QR Code

    private var shareAppLink: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text("Mind Cipher")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.15))
                Text("Scan to download")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))
            }
            Spacer()
            if let qrImage = generateQRCode(from: appStoreURL) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 256.0 / ciImage.extent.width
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func pegNumber(_ peg: PegColor) -> Int {
        if let idx = availableColors.firstIndex(of: peg) {
            return idx + 1
        }
        return peg.rawValue + 1
    }

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

// MARK: - Daily Challenge Share Card

struct DailyShareCardView: View {
    let rows: [ShareRowData]
    let codeLength: Int
    let maxAttempts: Int
    let won: Bool
    let attempts: Int
    let availableColors: [PegColor]

    private let accent = Color(red: 0.05, green: 0.60, blue: 0.55)
    private let warning = Color(red: 0.90, green: 0.52, blue: 0.05)
    private let danger = Color(red: 0.85, green: 0.20, blue: 0.20)
    private let bgTop = Color(red: 0.10, green: 0.15, blue: 0.25)
    private let bgBot = Color(red: 0.14, green: 0.20, blue: 0.32)
    private let cardBg = Color(red: 0.16, green: 0.22, blue: 0.34)
    private let subtleBg = Color.white.opacity(0.06)

    private let appStoreURL = "https://apps.apple.com/app/mind-cipher/id6777428188"

    private var streak: Int { DailyStreakManager.shared.currentStreak }
    private var totalCompleted: Int { DailyStreakManager.shared.totalCompleted }

    private var displayDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var stars: Int {
        guard won else { return 0 }
        let ratio = Double(attempts) / Double(maxAttempts)
        return ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            resultSection
            calendarHeatmap
                .padding(.horizontal, 16)
                .padding(.top, 14)
            guessBoardSection
            appLinkSection
        }
        .background(
            LinearGradient(colors: [bgTop, bgBot], startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(warning)
                Text("Daily Challenge")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(displayDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(subtleBg)
    }

    // MARK: - Result + Streak Badges

    private var resultSection: some View {
        VStack(spacing: 12) {
            if won {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(i < stars ? warning : .white.opacity(0.15))
                    }
                }
                Text("Solved in \(attempts)/\(maxAttempts) steps")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            } else {
                Text("Failed — \(rows.count)/\(maxAttempts)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(danger)
            }

            HStack(spacing: 12) {
                streakBadge
                totalBadge
            }
        }
        .padding(.top, 14)
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(streakBadgeColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: streakIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(streakBadgeColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(streak)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Day Streak")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(subtleBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(streakBadgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var streakIcon: String {
        if streak >= 30 { return "flame.circle.fill" }
        if streak >= 7 { return "flame.fill" }
        if streak >= 3 { return "flame" }
        return "bolt.fill"
    }

    private var streakBadgeColor: Color {
        if streak >= 30 { return Color(red: 1.0, green: 0.3, blue: 0.1) }
        if streak >= 7 { return warning }
        if streak >= 3 { return Color(red: 1.0, green: 0.65, blue: 0.2) }
        return accent
    }

    private var totalBadge: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(totalCompleted)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Total")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(subtleBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmap: some View {
        let cal = Calendar.current
        let today = Date()
        let comps = cal.dateComponents([.year, .month], from: today)
        let firstOfMonth = cal.date(from: comps)!
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let monthFmt = DateFormatter()
        monthFmt.dateFormat = "MMMM yyyy"
        let monthTitle = monthFmt.string(from: today)

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst - 1)
        for day in 1...daysInMonth {
            var dc = comps
            dc.day = day
            days.append(cal.date(from: dc))
        }
        while days.count % 7 != 0 { days.append(nil) }

        return VStack(spacing: 6) {
            Text(monthTitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 0) {
                ForEach(Array(["S","M","T","W","T","F","S"].enumerated()), id: \.offset) { _, d in
                    Text(d)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<days.count, id: \.self) { i in
                    if let date = days[i] {
                        heatmapCell(date: date, today: today, cal: cal, fmt: fmt)
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(subtleBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func heatmapCell(date: Date, today: Date, cal: Calendar, fmt: DateFormatter) -> some View {
        let key = fmt.string(from: date)
        let completed = DailyStreakManager.shared.isCompleted(key)
        let isToday = cal.isDateInToday(date)
        let isFuture = date > today
        let dayNum = cal.component(.day, from: date)

        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(heatmapCellColor(completed: completed, isToday: isToday, isFuture: isFuture))
                .frame(width: 28, height: 28)

            if isToday && !completed {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(warning, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
            }

            Text("\(dayNum)")
                .font(.system(size: 10, weight: completed ? .bold : .medium, design: .rounded))
                .foregroundStyle(
                    completed ? .white :
                    isToday ? warning :
                    isFuture ? .white.opacity(0.15) :
                    .white.opacity(0.35)
                )
        }
    }

    private func heatmapCellColor(completed: Bool, isToday: Bool, isFuture: Bool) -> Color {
        if completed { return accent.opacity(0.85) }
        if isFuture { return .white.opacity(0.03) }
        return .white.opacity(0.06)
    }

    // MARK: - Guess Board

    private var guessBoardSection: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                dailyGuessRow(row)
                if row.id < rows.count {
                    Rectangle().fill(.white.opacity(0.04)).frame(height: 1)
                        .padding(.leading, 32)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(subtleBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var dailyPegSize: CGFloat {
        codeLength <= 4 ? 28 : codeLength <= 5 ? 24 : 20
    }

    private func dailyGuessRow(_ row: ShareRowData) -> some View {
        HStack(spacing: 5) {
            Text("\(row.id)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 14)

            HStack(spacing: codeLength <= 4 ? 5 : 3) {
                ForEach(Array(row.guess.enumerated()), id: \.offset) { _, peg in
                    Circle()
                        .fill(dailyPegGrad(peg))
                        .frame(width: dailyPegSize, height: dailyPegSize)
                        .overlay(
                            Text("\(dailyPegNumber(peg))")
                                .font(.system(size: dailyPegSize * 0.42, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                        )
                }
            }

            Spacer(minLength: 4)

            dailyFeedbackDots(row.feedback)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private func dailyFeedbackDots(_ fb: Feedback) -> some View {
        let dotSize: CGFloat = codeLength <= 4 ? 14 : 11
        let types: [FeedbackType] =
            Array(repeating: .exact, count: fb.exact) +
            Array(repeating: .partial, count: fb.partial) +
            Array(repeating: .miss, count: max(0, codeLength - fb.exact - fb.partial))

        return HStack(spacing: 2) {
            ForEach(Array(types.enumerated()), id: \.offset) { _, t in
                dailyFeedbackDot(type: t, size: dotSize)
            }
        }
    }

    private func dailyFeedbackDot(type: FeedbackType, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(dailyFeedbackBgColor(type))
                .frame(width: size, height: size)

            switch type {
            case .exact:
                Circle().fill(accent).frame(width: size * 0.8, height: size * 0.8)
            case .partial:
                FeedbackTriangle().fill(warning).frame(width: size * 0.8, height: size * 0.8)
            case .miss:
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.85, weight: .black))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
    }

    private func dailyFeedbackBgColor(_ type: FeedbackType) -> Color {
        switch type {
        case .exact: return accent.opacity(0.2)
        case .partial: return warning.opacity(0.2)
        case .miss: return .white.opacity(0.06)
        }
    }

    // MARK: - App Link

    private var appLinkSection: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 1) {
                Text("Mind Cipher")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("Scan to download")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if let qrImage = generateDailyQRCode(from: appStoreURL) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(4)
                    .colorInvert()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func generateDailyQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 256.0 / ciImage.extent.width
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func dailyPegNumber(_ peg: PegColor) -> Int {
        if let idx = availableColors.firstIndex(of: peg) {
            return idx + 1
        }
        return peg.rawValue + 1
    }

    private func dailyPegCol(_ peg: PegColor) -> Color {
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

    private func dailyPegGrad(_ peg: PegColor) -> LinearGradient {
        let c = dailyPegCol(peg)
        return LinearGradient(colors: [c.opacity(0.85), c, c.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
