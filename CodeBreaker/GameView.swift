import SwiftUI
import GameKit
import StoreKit
import CoreImage.CIFilterBuiltins

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Accessibility text sizes: stack the legend and give the submit button its own row.
    private var isAX: Bool { dynamicTypeSize.isAccessibilitySize }
    
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
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var showPaywall = false
    @State private var paywallReason: PaywallReason = .classicLevels

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if viewModel.guessHistory.isEmpty || viewModel.engine?.lieMode == true {
                    feedbackLegend
                }

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
                .padding(.top, 8)
                .background(
                    AppTheme.paperFolder
                        .ignoresSafeArea(edges: .bottom)
                )
                .overlay(alignment: .top) {
                    Rectangle().fill(AppTheme.ink).frame(height: 1.5)
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
                            .font(AppFont.display(14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .paperCard(fill: AppTheme.bgCardLight)
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
            guard shown else { return }
            if viewModel.engine?.lieMode == true {
                lieRevealShowReal = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        lieRevealShowReal = true
                    }
                }
            }
            if case .won = viewModel.phase {
                presentCapPaywallIfNeeded()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: paywallReason)
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

    private func presentCapPaywallIfNeeded() {
        guard !storeManager.isPro, let level = viewModel.level else { return }
        let lie = viewModel.engine?.lieMode == true
        guard level.id == StoreManager.freeCap(lieMode: lie) else { return }
        let key = lie ? "paywall_auto_lie" : "paywall_auto_classic"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        paywallReason = lie ? .finishedLieFree : .finishedClassicFree
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showPaywall = true
        }
    }

    private var lieKickoffBanner: some View {
        VStack {
            VStack(spacing: 8) {
                StampView(text: "Top Secret", tone: .red, size: 12, rotation: -4)
                Text(L("lie.kickoff"))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .paperCard(fill: AppTheme.bgCardLight)
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
                    DossierCaption(text: L("achieve.toast"), color: AppTheme.warning)
                    Text(a.localizedTitle)
                        .font(AppFont.display(15, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()
            }
            .padding(14)
            .paperCard(fill: AppTheme.bgCardLight)
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
    }

    // MARK: - Top Bar

    /// Case-file header: caption line, case number, subtitle, attempts on the right.
    private var caseCaption: String {
        if viewModel.level != nil { return viewModel.engine?.lieMode == true ? L("case.lie") : L("case.classic") }
        if viewModel.isChallenge { return L("challenge.title") }
        if viewModel.mode == .duel { return L("game.duel") }
        if viewModel.mode == .online { return L("online.title") }
        if viewModel.isLieTaste { return L("taste.title") }
        if viewModel.isDailyChallenge { return L("daily.title") }
        return L("game.free")
    }

    private var caseTitle: String {
        if let level = viewModel.level { return L("case.no", level.id) }
        if viewModel.isDailyChallenge { return L("case.no", DailyCalendar.dayNumber()) }
        if viewModel.isLieTaste { return L("taste.subtitle") }
        return String(format: "No. %04d", Int((viewModel.engine?.seed ?? 0) % 10000))
    }

    private var caseSubtitle: String? {
        if let level = viewModel.level { return level.difficulty.localizedName }
        if viewModel.isLieTaste { return nil }
        if viewModel.engine?.lieMode == true { return L("lie.mode") }
        return nil
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .paperCard()
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 1) {
                DossierCaption(text: caseCaption)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(caseTitle)
                    .font(AppFont.display(22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let sub = caseSubtitle {
                    Text(sub)
                        .font(AppFont.label(11, weight: .regular))
                        .foregroundStyle(viewModel.engine?.lieMode == true ? AppTheme.danger : AppTheme.textSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                attemptsBadge
                if viewModel.timeRemaining > 0 {
                    Text("\(viewModel.timeRemaining)s")
                        .font(AppFont.mono(12, weight: .bold))
                        .foregroundStyle(viewModel.timeRemaining <= 15 ? AppTheme.danger : AppTheme.textSecondary)
                }
                if viewModel.engine?.lieMode == true {
                    StampView(text: "Top Secret", tone: .red, size: 8, rotation: -6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.ink).frame(height: 1.5).padding(.horizontal, 16)
        }
    }

    private var attemptsBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(viewModel.attemptsLeft)")
                .font(AppFont.display(18, weight: .bold))
                .foregroundStyle(viewModel.attemptsLeft <= 2 ? AppTheme.danger : AppTheme.textPrimary)
            Text(L("game.attempts"))
                .font(AppFont.label(10, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .paperCard()
        .fixedSize()
        .accessibilityLabel("\(viewModel.attemptsLeft) \(L("game.attempts"))")
    }

    // MARK: - Feedback Legend (one line, only before the first guess / in lie mode)

    private var feedbackLegend: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.guessHistory.isEmpty {
                AnyLayout(isAX ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))) {
                    legendItem(type: .exact, text: L("legend.exact.short"))
                    legendItem(type: .partial, text: L("legend.partial.short"))
                    legendItem(type: .miss, text: L("legend.miss.short"))
                }
            }
            if viewModel.engine?.lieMode == true {
                Text(L("lie.clue"))
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    private func legendItem(type: FeedbackType, text: String) -> some View {
        HStack(spacing: 4) {
            FeedbackDotView(type: type, size: 14)
            Text(text)
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
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

            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .boardLayout()
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
                            HStack(spacing: 10) {
                                Text(romanNumeral(i + 1))
                                    .font(AppFont.graphic(11, weight: .regular))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .frame(width: 26, alignment: .leading)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .frame(height: rowHeight)
                        }

                        TypewriterRule()
                            .padding(.leading, 44)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .boardLayout()
            }
            .onChange(of: viewModel.guessHistory.count) { _, _ in
                if let last = viewModel.guessHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .paperCard()
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    

    // MARK: - Current Guess Row

    private var slotSize: CGFloat {
        viewModel.codeLength <= 4 ? 52 : viewModel.codeLength <= 5 ? 46 : 40
    }

    private var pegSize: CGFloat {
        viewModel.codeLength <= 4 ? 34 : viewModel.codeLength <= 5 ? 30 : 26
    }

    /// Evidence tray: the row being assembled.
    private var currentGuessRow: some View {
        VStack(spacing: 6) {
            HStack {
                DossierCaption(text: L("case.tray"))
                Spacer()
                Text(romanNumeral(viewModel.guessHistory.count + 1))
                    .font(AppFont.graphic(11, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 4)
            HStack(spacing: viewModel.codeLength <= 4 ? 10 : 6) {
                ForEach(0..<viewModel.codeLength, id: \.self) { i in
                    currentSlot(index: i)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .paperCard(fill: AppTheme.bgCardLight)
        .padding(.horizontal, 16)
        .modifier(ShakeModifier(trigger: viewModel.shakeGuessRow))
        .boardLayout()
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
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? AppTheme.bgCardLight : AppTheme.paperFolder)
                .frame(width: slotSize, height: slotSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            isSelected ? AppTheme.accent : AppTheme.rule,
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [3, 3])
                        )
                )

            if let color = viewModel.currentGuess[index] {
                PegView(color: color, size: pegSize)
                    .transition(.scale.combined(with: .opacity))
            } else if let hint = hintColor {
                PegView(color: hint, size: pegSize)
                    .opacity(0.35)
            } else {
                Text("\(index + 1)")
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textMuted)
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
        .boardLayout()
    }

    private func colorButton(_ color: PegColor, size: CGFloat) -> some View {
        let marker = viewModel.noteMarker(position: viewModel.selectedSlot, color: color)
        let isEliminated = marker == .eliminated
        return Button {
            SoundManager.shared.playPlace()
            viewModel.selectColor(color)
        } label: {
            PegView(color: color, size: size)
                .overlay {
                    if isEliminated {
                        Circle()
                            .fill(AppTheme.paper.opacity(0.7))
                        Rectangle()
                            .fill(AppTheme.ink)
                            .frame(width: size * 0.9, height: 2)
                            .rotationEffect(.degrees(-30))
                    } else if marker == .confirmed {
                        Circle()
                            .stroke(AppTheme.accent, lineWidth: 2)
                            .frame(width: size + 6, height: size + 6)
                    }
                }
                .padding(3)
        }
        .disabled(viewModel.phase != .playing || isEliminated)
        .accessibilityLabel(color.displayName)
        .accessibilityIdentifier("peg.\(color.displayName.lowercased())")
    }

    // MARK: - Action Bar

    private func toolButton(_ systemName: String, active: Bool = false, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint ?? (active ? AppTheme.accent : AppTheme.textPrimary))
                .frame(width: 44, height: 48)
                .paperCard(fill: active ? AppTheme.bgCardLight : nil)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(active ? AppTheme.accent : .clear, lineWidth: 1.5)
                )
        }
    }

    private var submitButton: some View {
        Button {
            if viewModel.engine?.lieMode == true {
                SoundManager.shared.playLieSubmit()
            } else {
                SoundManager.shared.playSubmit()
            }
            viewModel.submitGuess()
        } label: {
            Text(L("game.analyze"))
                .font(AppFont.label(14, weight: .bold))
                .tracking(isAX ? 0 : 1.5)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(viewModel.canSubmit ? AppTheme.paper : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.canSubmit ? AppTheme.ink : AppTheme.paperFolder)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(viewModel.canSubmit ? .clear : AppTheme.rule, lineWidth: 1)
                )
        }
        .disabled(!viewModel.canSubmit)
    }

    private var actionBar: some View {
        VStack(spacing: 6) {
            if isAX { submitButton }
        HStack(spacing: 6) {
            toolButton("arrow.counterclockwise") {
                SoundManager.shared.playTap()
                for i in 0..<viewModel.codeLength {
                    viewModel.clearSlot(i)
                }
                viewModel.selectedSlot = 0
            }
            .disabled(viewModel.phase != .playing)
            .accessibilityLabel("Clear")

            toolButton("list.bullet.rectangle", active: viewModel.showNotes) {
                SoundManager.shared.playTap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.showNotes.toggle()
                }
            }
            .accessibilityLabel("Notes")

            ZStack(alignment: .topTrailing) {
                toolButton("person.fill.questionmark", tint: viewModel.canUseHint ? AppTheme.warning : AppTheme.textMuted) {
                    SoundManager.shared.playTap()
                    viewModel.useHint()
                }
                .disabled(!viewModel.canUseHint)
                .accessibilityLabel("Hint")

                Text("\(hintCoinManager.coins)")
                    .font(AppFont.label(9, weight: .bold))
                    .foregroundStyle(AppTheme.paper)
                    .frame(width: 16, height: 16)
                    .background(hintCoinManager.coins > 0 ? AppTheme.warning : AppTheme.textMuted, in: Circle())
                    .offset(x: 4, y: -4)
            }

            if isAX { Spacer(minLength: 0) } else { submitButton }

            toolButton("square.and.arrow.up") { shareImage() }
                .accessibilityLabel("Share")
        }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Result Overlay (case report)

    private var isWon: Bool {
        if case .won = viewModel.phase { return true }
        return false
    }

    private var resultOverlay: some View {
        ZStack {
            AppTheme.ink.opacity(0.45).ignoresSafeArea()
                .onTapGesture { }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    reportHeader
                    Rectangle().fill(AppTheme.ink).frame(height: 1.5)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    VStack(spacing: 12) {
                        if case .won(let attempts) = viewModel.phase {
                            reportLine(L("report.result"), value: L("result.win"))
                            reportLine(L("report.attempts"), value: L("result.win.steps", attempts))
                            if viewModel.isDailyChallenge { dailyScoreLine(attempts: attempts) }
                            starsLine(attempts: attempts)
                            hintCoinProgress
                        } else {
                            reportLine(L("report.result"), value: L("result.lose"))
                            Text(L("result.lose.desc"))
                                .font(AppFont.body(13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        revealedCodeRow
                        lieRevealSection
                    }

                    TypewriterRule().padding(.vertical, 14)

                    resultButtons
                }
                .padding(22)
                .paperCard(fill: AppTheme.bgCardLight)
                .overlay(alignment: .topTrailing) {
                    StampView(text: isWon ? "Case Closed" : "Unsolved", tone: .red, size: 15, rotation: -12)
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                        .opacity(showResult ? 1 : 0)
                        .scaleEffect(showResult ? 1 : 1.6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.25), value: showResult)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
    }

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            DossierCaption(text: L("report.title"))
            Text(caseTitle)
                .font(AppFont.display(24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(caseCaption + (caseSubtitle.map { " · \($0)" } ?? ""))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 110)
    }

    private func reportLine(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.display(15, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func dailyScoreLine(attempts: Int) -> some View {
        let elapsed = Int(Date().timeIntervalSince(viewModel.gameStartTime ?? Date()))
        let score = (viewModel.maxAttempts - attempts) * 10000 + max(0, 10000 - elapsed)
        return HStack(alignment: .firstTextBaseline) {
            Text(L("report.score"))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("\(score)")
                .font(AppFont.mono(15, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            if GameCenterManager.shared.isAuthenticated {
                Text(L("game.submitted"))
                    .font(AppFont.label(10, weight: .regular))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private func starsLine(attempts: Int) -> some View {
        let ratio = Double(attempts) / Double(viewModel.maxAttempts)
        let stars = ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
        return HStack {
            Text(L("report.rating"))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(i < stars ? AppTheme.accent : AppTheme.textMuted)
                }
            }
        }
    }

    private var hintCoinProgress: some View {
        let wins = hintCoinManager.winsTowardsCoin
        let needed = HintCoinManager.winsPerCoin

        return HStack {
            Text(L("store.hints"))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            if hintCoinManager.justEarnedCoin {
                Text(L("game.hint.earned", hintCoinManager.coins))
                    .font(AppFont.display(13, weight: .bold))
                    .foregroundStyle(AppTheme.warning)
            } else {
                Text(L("game.hint.progress", wins, needed))
                    .font(AppFont.body(12))
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 3) {
                    ForEach(0..<needed, id: \.self) { i in
                        Circle()
                            .fill(i < wins ? AppTheme.warning : .clear)
                            .overlay(Circle().stroke(AppTheme.rule, lineWidth: 1))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private var revealedCodeRow: some View {
        HStack {
            Text(L("result.code"))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<viewModel.secretCode.count, id: \.self) { i in
                    PegView(color: viewModel.secretCode[i], size: 28)
                }
            }
            .boardLayout()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.paperFolder, in: RoundedRectangle(cornerRadius: 3))
    }

    @ViewBuilder
    private var lieRevealSection: some View {
        if viewModel.engine?.lieMode == true {
            if let lieGuess = viewModel.engine?.lieAtGuess, lieGuess <= viewModel.guessHistory.count {
                let record = viewModel.guessHistory[lieGuess - 1]
                let realFeedback = viewModel.engine!.computeRealFeedback(guess: record.guess)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        StampView(text: L("lie.stamp"), tone: .red, size: 9, rotation: 0)
                        Text(L("lie.reveal", lieGuess))
                            .font(AppFont.display(13, weight: .bold))
                            .foregroundStyle(AppTheme.danger)
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            DossierCaption(text: L("lie.fake"), color: AppTheme.textMuted)
                            FeedbackDotsRow(feedback: record.feedback, codeLength: viewModel.codeLength, size: 16)
                                .opacity(lieRevealShowReal ? 0.4 : 1)
                        }

                        Image(systemName: "arrow.forward")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.top, 12)
                            .opacity(lieRevealShowReal ? 1 : 0.25)

                        VStack(alignment: .leading, spacing: 4) {
                            DossierCaption(text: L("lie.real.short"), color: AppTheme.textMuted)
                            FeedbackDotsRow(feedback: realFeedback, codeLength: viewModel.codeLength, size: 16)
                                .scaleEffect(lieRevealShowReal ? 1 : 0.7)
                                .opacity(lieRevealShowReal ? 1 : 0)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(AppTheme.danger, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            } else {
                Text(L("lie.notrigger"))
                    .font(AppFont.body(12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var resultButtons: some View {
        VStack(spacing: 10) {
            if let level = viewModel.level {
                if case .won = viewModel.phase,
                   let next = LevelManager.shared.level(for: level.id + 1) {
                    let lie = viewModel.engine?.lieMode == true
                    if storeManager.isLevelLocked(next.id, lieMode: lie) {
                        Button {
                            paywallReason = lie ? .finishedLieFree : .finishedClassicFree
                            if level.id != StoreManager.freeCap(lieMode: lie) {
                                paywallReason = lie ? .lieLevels : .classicLevels
                            }
                            showPaywall = true
                        } label: { Text(L("paywall.unlock")) }
                        .buttonStyle(InkButtonStyle())
                    } else {
                        Button {
                            showResult = false
                            confettiParticles = []
                            if lie {
                                let extra = level.difficulty.lieExtraAttempts
                                viewModel.startLieGame(level: next, totalAttempts: next.maxAttempts + extra)
                            } else {
                                viewModel.startGame(level: next)
                            }
                        } label: { Text(L("result.next")) }
                        .buttonStyle(InkButtonStyle())
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
                    } label: { Text(L("result.retry")) }
                    .buttonStyle(InkButtonStyle())
                }
            } else {
                Button {
                    showResult = false
                    confettiParticles = []
                    let wasLie = viewModel.engine?.lieMode ?? false
                    viewModel.startFreePlay(difficulty: viewModel.lastDifficulty, lieMode: wasLie)
                } label: { Text(L("result.again")) }
                .buttonStyle(InkButtonStyle())
            }

            HStack(spacing: 10) {
                Button { shareImage() } label: {
                    Label(L("result.share"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(InkButtonStyle(prominent: false))

                if case .won = viewModel.phase {
                    Button { shareChallengeLink() } label: {
                        Label(L("result.challenge"), systemImage: "person.badge.plus")
                    }
                    .buttonStyle(InkButtonStyle(prominent: false))
                }
            }

            Button {
                confettiParticles = []
                dismiss()
            } label: {
                Text(L("result.back"))
                    .font(AppFont.label(12, weight: .regular))
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

        let text = "\(L("share.challenge.text"))\n\(url.absoluteString)"
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
                    availableColors: viewModel.availableColors,
                    isLieMode: isLie
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
                    difficultyName: viewModel.lastDifficulty.localizedName,
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
        let colors: [Color] = [AppTheme.accent, AppTheme.ink, AppTheme.paperFolder, AppTheme.accent, AppTheme.warning]
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

    private var isSuspect: Bool { gameOver && feedback.isLie }

    var body: some View {
        HStack(spacing: 10) {
            Text(romanNumeral(index))
                .font(AppFont.graphic(11, weight: isSuspect ? .bold : .regular))
                .foregroundStyle(isSuspect ? AppTheme.danger : AppTheme.textSecondary)
                .frame(width: 26, alignment: .leading)

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

            if isSuspect {
                StampView(text: L("lie.suspect"), tone: .red, size: 8, rotation: -8)
                    .scaleEffect(stampIn ? 1 : 1.7)
                    .opacity(stampIn ? 1 : 0)
            }

            feedbackDots
                .opacity(revealed ? (glitch ? 0.2 : 1.0) : 0)
                .offset(x: glitch ? 1.5 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.4), value: revealed)
                .animation(.easeInOut(duration: 0.06), value: glitch)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(isSuspect ? AppTheme.danger.opacity(0.07) : .clear)
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
            if isSuspect {
                slamLieStamp()
            }
        }
        .onChange(of: gameOver) { _, over in
            if over && feedback.isLie { slamLieStamp() }
        }
        .boardLayout()
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
        FeedbackMarks(feedback: feedback, codeLength: codeLength, size: feedbackDotSize)
    }
}

/// Feedback marks laid out in one row (≤4 pegs) or two rows (longer codes).
struct FeedbackMarks: View {
    let feedback: Feedback
    let codeLength: Int
    let size: CGFloat

    var body: some View {
        let exact = feedback.exact
        let partial = feedback.partial
        let empty = max(0, codeLength - exact - partial)
        let allTypes: [FeedbackType] =
            Array(repeating: .exact, count: exact) +
            Array(repeating: .partial, count: partial) +
            Array(repeating: .miss, count: empty)

        Group {
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
            Rectangle().fill(AppTheme.ink).frame(height: 1).padding(.horizontal, 12)
            gridContent
        }
        .paperCard(fill: AppTheme.bgCardLight)
        .padding(.horizontal, 12)
    }

    private var header: some View {
        HStack {
            DossierCaption(text: L("game.notes"), color: AppTheme.textPrimary)

            Spacer()

            Button {
                SoundManager.shared.playTap()
                viewModel.clearAllNotes()
            } label: {
                Text(L("game.notes.clear"))
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(AppTheme.rule, lineWidth: 1))
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.showNotes = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 28, height: 28)
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
                            .font(AppFont.label(12, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
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
                        PegView(color: color, size: cellSize - 10)
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
        .boardLayout()
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
                RoundedRectangle(cornerRadius: 2)
                    .stroke(AppTheme.rule, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 2).fill(cellBackground(marker))
                    )
                    .frame(width: cellSize - 6, height: cellSize - 6)

                switch marker {
                case .eliminated:
                    Image(systemName: "xmark")
                        .font(.system(size: cellSize * 0.38, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                case .confirmed:
                    Image(systemName: "checkmark")
                        .font(.system(size: cellSize * 0.38, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
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
        case .eliminated: return AppTheme.danger.opacity(0.08)
        case .confirmed: return AppTheme.ink.opacity(0.08)
        case nil: return .clear
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

private let shareAppStoreURL = "https://apps.apple.com/app/mind-cipher/id6777428188"

private func shareQRCode(from string: String) -> UIImage? {
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

/// Shared footer: app mark + QR on paper.
private struct ShareFooter: View {
    let skin: AppSkin
    var body: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(L("app.title"))
                    .font(AppFont.display(13, weight: .bold))
                    .foregroundStyle(skin.ink)
                Text(L("share.scan"))
                    .font(AppFont.body(10))
                    .foregroundStyle(skin.inkFaded)
            }
            Spacer()
            if let qrImage = shareQRCode(from: shareAppStoreURL) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .cornerRadius(2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

/// Ledger of guesses used by both share cards.
private struct ShareLedger: View {
    let rows: [ShareRowData]
    let codeLength: Int
    let skin: AppSkin

    private var pegSize: CGFloat { codeLength <= 4 ? 28 : codeLength <= 5 ? 24 : 20 }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                HStack(spacing: 10) {
                    Text(romanNumeral(row.id))
                        .font(AppFont.graphic(11, weight: row.isLie ? .bold : .regular))
                        .foregroundStyle(row.isLie ? skin.stamp : skin.inkFaded)
                        .frame(width: 26, alignment: .leading)
                    HStack(spacing: codeLength <= 4 ? 6 : 4) {
                        ForEach(Array(row.guess.enumerated()), id: \.offset) { _, peg in
                            PegView(color: peg, size: pegSize)
                        }
                    }
                    Spacer(minLength: 4)
                    if row.isLie {
                        StampView(text: L("lie.suspect"), tone: .red, size: 7, rotation: -8)
                    }
                    FeedbackMarks(feedback: row.feedback, codeLength: codeLength, size: codeLength <= 4 ? 16 : 12)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(row.isLie ? skin.stamp.opacity(0.07) : .clear)
                TypewriterRule(color: skin.rule).padding(.leading, 44)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(skin.paperCard)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(skin.rule, lineWidth: 1))
        )
        .boardLayout()
    }
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

    private let skin = AppSkin.dossier

    private var stars: Int {
        guard won else { return 0 }
        let ratio = Double(attempts) / Double(maxAttempts)
        return ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
    }

    private var caseTitle: String {
        if let lid = levelId { return L("case.no", lid) }
        return L("game.free")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(skin.ink).frame(height: 1.5).padding(.horizontal, 18)

            ShareLedger(rows: rows, codeLength: codeLength, skin: skin)
                .padding(.horizontal, 18)
                .padding(.top, 14)

            statusBlock
                .padding(.horizontal, 18)
                .padding(.top, 12)

            TypewriterRule(color: skin.rule).padding(.horizontal, 18).padding(.top, 12)
            ShareFooter(skin: skin)
        }
        .background(skin.paper)
        .boardLayout()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text((isLieMode ? L("case.lie") : L("case.classic")).uppercased())
                    .font(AppFont.label(10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(skin.inkFaded)
                Text(caseTitle)
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(skin.ink)
                Text("\(difficultyName) · \(codeLength)×\(colorCount) · \(rows.count)/\(maxAttempts)")
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(skin.inkFaded)
            }
            Spacer()
            if !isPlaying {
                StampView(text: won ? "Case Closed" : "Unsolved", tone: .red, size: 12, rotation: -10)
                    .padding(.top, 6)
            } else if isLieMode {
                StampView(text: "Top Secret", tone: .red, size: 10, rotation: -10)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isPlaying {
                Text(L("share.inprogress", rows.count, maxAttempts))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(skin.ink)
            } else if won {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundStyle(i < stars ? skin.stamp : skin.inkMuted)
                        }
                    }
                    Text(L("share.solved", attempts, maxAttempts))
                        .font(AppFont.display(14, weight: .bold))
                        .foregroundStyle(skin.ink)
                }
            } else {
                Text(L("share.failed", rows.count, maxAttempts))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(skin.stamp)
            }

            if isLieMode, let step = lieStep, let fakeFb = lieFakeFeedback, let realFb = lieRealFeedback {
                HStack(spacing: 10) {
                    Text(L("lie.reveal", step))
                        .font(AppFont.label(11, weight: .bold))
                        .foregroundStyle(skin.stamp)
                    FeedbackDotsRow(feedback: fakeFb, codeLength: codeLength, size: 13)
                        .opacity(0.45)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(skin.inkFaded)
                    FeedbackDotsRow(feedback: realFb, codeLength: codeLength, size: 13)
                }
            } else if isLieMode {
                Text(L("share.lie.banner"))
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(skin.stamp)
            }

            HStack(spacing: 6) {
                ForEach(availableColors) { peg in
                    PegView(color: peg, size: 20)
                }
                Spacer()
                Text(L("share.cta"))
                    .font(AppFont.body(11, weight: .medium))
                    .foregroundStyle(skin.inkFaded)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    var isLieMode: Bool = false

    private let skin = AppSkin.dossier

    private var streak: Int { DailyStreakManager.shared.currentStreak }
    private var totalCompleted: Int { DailyStreakManager.shared.totalCompleted }

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.calendar = DailyCalendar.gregorian
        formatter.locale = LanguageManager.shared.locale
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var stars: Int {
        guard won else { return 0 }
        let ratio = Double(attempts) / Double(maxAttempts)
        return ratio <= 0.3 ? 3 : ratio <= 0.6 ? 2 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(skin.ink).frame(height: 1.5).padding(.horizontal, 18)

            resultLine
                .padding(.horizontal, 18)
                .padding(.top, 12)

            ShareLedger(rows: rows, codeLength: codeLength, skin: skin)
                .padding(.horizontal, 18)
                .padding(.top, 12)

            calendarSheet
                .padding(.horizontal, 18)
                .padding(.top, 12)

            TypewriterRule(color: skin.rule).padding(.horizontal, 18).padding(.top, 12)
            ShareFooter(skin: skin)
        }
        .background(skin.paper)
        .boardLayout()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text((isLieMode ? L("share.daily.lie") : L("daily.title")).uppercased())
                    .font(AppFont.label(10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(skin.inkFaded)
                Text(L("case.no", DailyCalendar.dayNumber()))
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(skin.ink)
                Text(displayDate)
                    .font(AppFont.label(11, weight: .regular))
                    .foregroundStyle(skin.inkFaded)
            }
            Spacer()
            StampView(text: won ? "Case Closed" : "Unsolved", tone: .red, size: 12, rotation: -10)
                .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var resultLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            if won {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(i < stars ? skin.stamp : skin.inkMuted)
                    }
                }
                Text(L("share.solved", attempts, maxAttempts))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(skin.ink)
            } else {
                Text(L("share.failed", rows.count, maxAttempts))
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(skin.stamp)
            }
            Spacer()
            statBadge(value: streak, label: L("daily.streak"))
            statBadge(value: totalCompleted, label: L("daily.total"))
        }
    }

    private func statBadge(value: Int, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(value)")
                .font(AppFont.display(18, weight: .bold))
                .foregroundStyle(skin.ink)
            Text(label.uppercased())
                .font(AppFont.label(8, weight: .regular))
                .tracking(1)
                .foregroundStyle(skin.inkFaded)
        }
    }

    // MARK: - Calendar (stamped grid)

    private var calendarSheet: some View {
        let cal = DailyCalendar.gregorian
        let today = Date()
        let comps = cal.dateComponents([.year, .month], from: today)
        let firstOfMonth = cal.date(from: comps)!
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count

        let monthFmt = DateFormatter()
        monthFmt.calendar = cal
        monthFmt.locale = LanguageManager.shared.locale
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
            HStack {
                Text(monthTitle.uppercased())
                    .font(AppFont.label(10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(skin.inkFaded)
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(Array(DailyCalendar.weekdaySymbols(locale: LanguageManager.shared.locale).enumerated()), id: \.offset) { _, d in
                    Text(d)
                        .font(AppFont.label(8, weight: .regular))
                        .foregroundStyle(skin.inkMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<days.count, id: \.self) { i in
                    if let date = days[i] {
                        dayCell(date: date, today: today, cal: cal)
                    } else {
                        Color.clear.frame(height: 26)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(skin.paperCard)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(skin.rule, lineWidth: 1))
        )
    }

    private func dayCell(date: Date, today: Date, cal: Calendar) -> some View {
        let key = DailyCalendar.dayKey(date)
        let completed = DailyStreakManager.shared.isCompleted(key)
        let isToday = cal.isDateInToday(date)
        let isFuture = date > today
        let dayNum = cal.component(.day, from: date)

        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(isToday ? skin.ink : skin.rule, lineWidth: isToday ? 1.5 : 1)
            Text("\(dayNum)")
                .font(AppFont.label(10, weight: .regular))
                .foregroundStyle(isFuture ? skin.inkMuted.opacity(0.5) : skin.inkFaded)
            if completed {
                Circle()
                    .stroke(skin.stamp, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-8))
                    .opacity(0.9)
            }
        }
        .frame(height: 26)
    }
}
