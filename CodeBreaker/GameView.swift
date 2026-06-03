import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showHint = false
    @State private var hintText = ""
    @State private var showResult = false
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showTutorial: Bool
    @State private var tutorialStep = 0
    @State private var showShareSheet = false
    @State private var revealedSecretCount = 0
    @State private var secretGlow = false

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        _showTutorial = State(initialValue: !UserDefaults.standard.bool(forKey: "tutorialSeen"))
    }

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                secretCodeBar
                Divider().overlay(AppTheme.textMuted.opacity(0.3)).padding(.horizontal)
                guessBoard
                Spacer(minLength: 8)
                currentGuessRow
                colorPicker
                actionBar
            }

            if showResult { resultOverlay }

            ForEach(confettiParticles) { p in
                ConfettiPiece(particle: p)
            }

            if showTutorial { tutorialOverlay }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.phase) { _, phase in
            if phase != .playing {
                revealSecretSequentially()
                if case .won = phase {
                    SoundManager.shared.playWin()
                    spawnConfetti()
                } else {
                    SoundManager.shared.playLose()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(viewModel.codeLength) * 0.2 + 0.6) {
                    withAnimation(.spring(response: 0.5)) { showResult = true }
                }
            }
        }
        .alert("提示", isPresented: $showHint) {
            Button("收到！") { }
        } message: {
            Text(hintText)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .glassCard(cornerRadius: 10)
            }

            Spacer()

            VStack(spacing: 2) {
                if let level = viewModel.level {
                    Text("关卡 \(level.id)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(level.difficulty.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                } else if viewModel.mode == .duel {
                    Text("双人对战")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                } else {
                    Text("自由模式")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if viewModel.timeRemaining > 0 {
                    timerBadge
                }
                attemptsBadge
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
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.attemptsLeft <= 2 ? AppTheme.danger : AppTheme.accent)
            Text("次")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 8)
    }

    // MARK: - Secret Code

    private var secretCodeBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<viewModel.codeLength, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.bgCardLight)
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

            if viewModel.phase == .playing && !viewModel.hintUsed {
                Button {
                    SoundManager.shared.playTap()
                    if let hint = viewModel.useHint() {
                        hintText = hint
                        showHint = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                        Text("提示")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Guess Board

    private var guessBoard: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(viewModel.guessHistory.enumerated()), id: \.element.id) { index, record in
                        GuessRowView(
                            index: index + 1,
                            guess: record.guess,
                            feedback: record.feedback,
                            codeLength: viewModel.codeLength
                        )
                        .id(record.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    if viewModel.phase == .playing {
                        ForEach(0..<emptyRowCount, id: \.self) { i in
                            emptyRow(number: viewModel.guessHistory.count + i + 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.guessHistory.count) { _, _ in
                if let last = viewModel.guessHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyRowCount: Int {
        max(0, min(4, viewModel.attemptsLeft - 1))
    }

    private func emptyRow(number: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted.opacity(0.4))
                .frame(width: 20)

            HStack(spacing: 6) {
                ForEach(0..<viewModel.codeLength, id: \.self) { _ in
                    Circle()
                        .stroke(AppTheme.textMuted.opacity(0.15), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }
            }

            Spacer()

            HStack(spacing: 3) {
                ForEach(0..<viewModel.codeLength, id: \.self) { _ in
                    Circle()
                        .stroke(AppTheme.textMuted.opacity(0.1), lineWidth: 1)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(0.5)
    }

    // MARK: - Current Guess Row

    private var currentGuessRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<viewModel.codeLength, id: \.self) { i in
                currentSlot(index: i)
            }
        }
        .padding(.horizontal, 20)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppTheme.bgCardLight.opacity(1.2) : AppTheme.bgCardLight)
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? AppTheme.accent : Color.white.opacity(0.05),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(color: isSelected ? AppTheme.accent.opacity(0.2) : .clear, radius: 8)

            if let color = viewModel.currentGuess[index] {
                PegView(color: color, size: 34)
                    .transition(.scale.combined(with: .opacity))
            } else if isSelected {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 34, height: 34)
            }

            if isSelected {
                VStack {
                    Spacer()
                    Triangle()
                        .fill(AppTheme.accent)
                        .frame(width: 8, height: 5)
                        .offset(y: 4)
                }
                .frame(width: 52, height: 52)
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
        .accessibilityLabel("槽位 \(index + 1)")
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.availableColors) { color in
                    colorButton(color)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private func colorButton(_ color: PegColor) -> some View {
        let isUsed = viewModel.currentGuess.contains(color)
        let isEliminated = viewModel.eliminatedColors.contains(color)
        return Button {
            SoundManager.shared.playPlace()
            viewModel.selectColor(color)
        } label: {
            ZStack {
                PegView(color: color, size: 42)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .opacity(isEliminated ? 0.35 : 1.0)

                if isUsed {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 42, height: 42)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                } else if isEliminated {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.danger.opacity(0.8))
                }
            }
        }
        .disabled(viewModel.phase != .playing)
        .accessibilityLabel(color.displayName + "色" + (isEliminated ? "（已排除）" : ""))
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 46, height: 50)
                    .glassCard(cornerRadius: 12)
            }
            .disabled(viewModel.phase != .playing)

            Button {
                SoundManager.shared.playTap()
                viewModel.undoLastGuess()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(viewModel.undoAvailable ? AppTheme.warning : AppTheme.textMuted)
                    .frame(width: 46, height: 50)
                    .glassCard(cornerRadius: 12)
            }
            .disabled(!viewModel.undoAvailable || viewModel.phase != .playing)

            Button {
                SoundManager.shared.playSubmit()
                viewModel.submitGuess()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                    Text("提交")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(viewModel.canSubmit ? AppTheme.bgDark : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canSubmit ? AppTheme.accent : AppTheme.bgCardLight)
                )
            }
            .disabled(!viewModel.canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 20) {
                if case .won(let attempts) = viewModel.phase {
                    winContent(attempts: attempts)
                } else {
                    loseContent
                }
            }
            .padding(32)
            .glassCard(cornerRadius: 24)
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

            Text("密码破译成功！")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("用了 \(attempts) 步完成破译")
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

            Text("破译失败")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("密码未能在限定次数内破解")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            revealedCodeRow

            resultButtons
        }
    }

    private var revealedCodeRow: some View {
        HStack(spacing: 8) {
            Text("密码：")
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
                    let text = viewModel.generateShareText()
                    showShareSheet = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        shareText(text)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("分享")
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
                            Text("下一关 →")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.bgDark)
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
                            Text("重新挑战")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.bgDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else {
                    Button {
                        showResult = false
                        confettiParticles = []
                        viewModel.startFreePlay(difficulty: viewModel.lastDifficulty)
                    } label: {
                        Text("再来一局")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.bgDark)
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
                Text("返回")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    private func shareText(_ text: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = root.view
        root.present(vc, animated: true)
    }

    // MARK: - Tutorial Overlay

    private var tutorialOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: tutorialIcons[tutorialStep])
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accent)

                Text(tutorialTitles[tutorialStep])
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(tutorialTexts[tutorialStep])
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: 6) {
                    ForEach(0..<tutorialTitles.count, id: \.self) { i in
                        Circle()
                            .fill(i == tutorialStep ? AppTheme.accent : AppTheme.textMuted)
                            .frame(width: 6, height: 6)
                    }
                }

                Button {
                    if tutorialStep < tutorialTitles.count - 1 {
                        withAnimation(.spring(response: 0.3)) { tutorialStep += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: "tutorialSeen")
                        withAnimation(.spring(response: 0.3)) { showTutorial = false }
                    }
                } label: {
                    Text(tutorialStep < tutorialTitles.count - 1 ? "下一步" : "开始破译！")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.bgDark)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(40)
        }
    }

    private let tutorialIcons = [
        "lock.shield.fill", "circle.grid.2x2.fill", "checkmark.circle.fill", "lightbulb.fill"
    ]
    private let tutorialTitles = [
        "破译隐藏密码", "选择颜色填入", "解读反馈线索", "善用提示"
    ]
    private let tutorialTexts = [
        "系统生成了一组隐藏的颜色密码\n你需要在有限次数内猜出正确组合",
        "点击底部颜色球放入猜测槽位\n填满所有位置后点击提交",
        "🟢 绿色 = 颜色和位置都对\n🟠 橙色 = 颜色对但位置不对\n⚪ 空圈 = 该颜色不在密码中",
        "每局有一次提示机会\n会告诉你某个位置的正确颜色"
    ]

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
    @State private var revealed = false

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                revealed = true
            }
        }
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
                    .stroke(AppTheme.textMuted, lineWidth: 1)
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
