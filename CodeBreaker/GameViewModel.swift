import SwiftUI
import Combine

enum GamePhase: Equatable {
    case playing
    case won(attempts: Int)
    case lost
}

enum NoteMarker: Equatable {
    case eliminated
    case confirmed
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var engine: GameEngine!
    @Published var guessHistory: [GuessRecord] = []
    @Published var currentGuess: [PegColor?] = []
    @Published var phase: GamePhase = .playing
    @Published var selectedSlot: Int = 0
    
    @Published var showSecret: Bool = false
    @Published var timeRemaining: Int = 0
    @Published var shakeGuessRow: Bool = false

    // Notes system: [position: [color: marker]]
    @Published var notes: [[PegColor: NoteMarker]] = []
    @Published var showNotes: Bool = false

    // Hint system
    @Published var hintUsed: Bool = false
    @Published var hintedPositions: Set<Int> = []
    @Published var lastHintMessage: String?

    var canUseHint: Bool {
        phase == .playing && !hintUsed && secretCode.count > 0 && HintCoinManager.shared.coins > 0
    }

    var mode: GameMode = .freePlay
    var level: Level?
    var lastDifficulty: Difficulty = .easy
    var isDailyChallenge: Bool = false
    var gameStartTime: Date?
    private var timer: Timer?

    var codeLength: Int { engine?.codeLength ?? 4 }
    var availableColors: [PegColor] { engine?.availableColors ?? [] }
    var maxAttempts: Int { engine?.maxAttempts ?? 7 }
    var attemptsLeft: Int { maxAttempts - guessHistory.count }
    var secretCode: [PegColor] { engine?.secretCode ?? [] }

    var canSubmit: Bool {
        phase == .playing && currentGuess.allSatisfy { $0 != nil }
    }

    var eliminatedColors: Set<PegColor> { [] }

    // MARK: - Notes

    func toggleNote(position: Int, color: PegColor) {
        guard position < notes.count else { return }
        let current = notes[position][color]
        switch current {
        case nil:
            notes[position][color] = .eliminated
        case .eliminated:
            notes[position][color] = .confirmed
        case .confirmed:
            notes[position][color] = nil
        }
    }

    func noteMarker(position: Int, color: PegColor) -> NoteMarker? {
        guard position < notes.count else { return nil }
        return notes[position][color]
    }

    func toggleRow(color: PegColor) {
        let allEliminated = (0..<codeLength).allSatisfy { notes[$0][color] == .eliminated }
        let allConfirmed = (0..<codeLength).allSatisfy { notes[$0][color] == .confirmed }
        let next: NoteMarker?
        if allEliminated {
            next = .confirmed
        } else if allConfirmed {
            next = nil
        } else {
            next = .eliminated
        }
        for pos in 0..<codeLength {
            notes[pos][color] = next
        }
    }

    func toggleColumn(position: Int) {
        guard position < notes.count else { return }
        let allEliminated = availableColors.allSatisfy { notes[position][$0] == .eliminated }
        for color in availableColors {
            notes[position][color] = allEliminated ? nil : .eliminated
        }
    }

    func clearAllNotes() {
        notes = Array(repeating: [:], count: codeLength)
    }

    func startGame(level: Level) {
        self.level = level
        self.mode = .campaign(level: level.id)
        engine = GameEngine(
            codeLength: level.codeLength,
            colorCount: level.colorCount,
            allowDuplicates: level.allowDuplicates,
            maxAttempts: level.maxAttempts
        )
        resetState()
        if level.timeLimitSeconds > 0 {
            timeRemaining = level.timeLimitSeconds
            startTimer()
        }
    }

    func startLieGame(level: Level, totalAttempts: Int) {
        self.level = level
        self.mode = .campaign(level: level.id)
        engine = GameEngine(
            codeLength: level.codeLength,
            colorCount: level.colorCount,
            allowDuplicates: level.allowDuplicates,
            maxAttempts: totalAttempts,
            lieMode: true
        )
        resetState()
    }

    func startFreePlay(difficulty: Difficulty, lieMode: Bool = false) {
        self.level = nil
        self.mode = .freePlay
        self.lastDifficulty = difficulty
        let extraAttempts: Int
        if !lieMode {
            extraAttempts = 0
        } else {
            // 余量 = 总步数 - 最优所需, 目标: 8 > 6 > 6 > 4 > 4 > 2
            switch difficulty {
            case .beginner: extraAttempts = 5  // 总15, 需~7, 余量8
            case .easy: extraAttempts = 7      // 总15, 需9,  余量6
            case .medium: extraAttempts = 8    // 总15, 需9,  余量6
            case .hard: extraAttempts = 7      // 总15, 需11, 余量4
            case .expert: extraAttempts = 7    // 总16, 需12, 余量4
            case .master: extraAttempts = 5    // 总15, 需13, 余量2
            }
        }
        engine = GameEngine(
            codeLength: difficulty.codeLength,
            colorCount: difficulty.colorCount,
            allowDuplicates: difficulty.allowDuplicates,
            maxAttempts: difficulty.maxAttempts + extraAttempts,
            lieMode: lieMode
        )
        resetState()
    }

    func startDuel(secretCode: [PegColor], colorCount: Int, maxAttempts: Int) {
        self.level = nil
        self.mode = .duel
        engine = GameEngine(
            secretCode: secretCode,
            colorCount: colorCount,
            maxAttempts: maxAttempts
        )
        resetState()
    }

    func startChallenge(seed: UInt64, codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false) {
        self.level = nil
        self.mode = .duel
        engine = GameEngine(
            seed: seed,
            codeLength: codeLength,
            colorCount: colorCount,
            allowDuplicates: allowDuplicates,
            maxAttempts: maxAttempts,
            lieMode: lieMode
        )
        resetState()
    }

    private func resetState() {
        guessHistory = []
        currentGuess = Array(repeating: nil, count: codeLength)
        phase = .playing
        selectedSlot = 0
        
        showSecret = false
        shakeGuessRow = false
        notes = Array(repeating: [:], count: codeLength)
        showNotes = false
        hintUsed = false
        hintedPositions = []
        gameStartTime = Date()
    }

    // MARK: - Hint

    func useHint() {
        guard canUseHint else { return }
        guard HintCoinManager.shared.spendCoin() else { return }
        hintUsed = true

        // Strategy: find the most useful logical deduction
        // Priority 1: Eliminate multiple colors from a position that has few marks
        // Priority 2: Confirm a color in a position

        let deduction = findBestDeduction()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            applyDeduction(deduction)
        }
    }

    private enum HintDeduction {
        case eliminateFromPosition(position: Int, colors: [PegColor])
        case confirmPosition(position: Int, color: PegColor)
    }

    private func findBestDeduction() -> HintDeduction {
        // Find a position where we can reveal the most info
        // Prefer positions that haven't been hinted and don't have the correct guess
        let unhinted = (0..<codeLength).filter { pos in
            !hintedPositions.contains(pos) && currentGuess[pos] != secretCode[pos]
        }
        let targetPositions = unhinted.isEmpty ? Array(0..<codeLength) : unhinted

        // For each candidate position, check how many colors are NOT yet eliminated
        var bestPos = targetPositions.first ?? 0
        var bestUnmarked = 0
        for pos in targetPositions {
            let unmarked = availableColors.filter { notes[pos][$0] == nil }.count
            if unmarked > bestUnmarked {
                bestUnmarked = unmarked
                bestPos = pos
            }
        }

        let correctColor = secretCode[bestPos]
        let wrongColors = availableColors.filter { $0 != correctColor && notes[bestPos][$0] != .eliminated }
        let totalPossible = wrongColors.count + 1 // +1 for the correct color

        // Ensure at least 3 possibilities remain after elimination (keeps it challenging)
        let maxEliminate = max(0, totalPossible - 3)

        if maxEliminate >= 1 && wrongColors.count > 1 {
            let eliminateCount = min(maxEliminate, max(1, wrongColors.count / 3))
            let toEliminate = Array(wrongColors.shuffled().prefix(eliminateCount))
            return .eliminateFromPosition(position: bestPos, colors: toEliminate)
        } else if wrongColors.count == 1 || totalPossible <= 3 {
            return .confirmPosition(position: bestPos, color: correctColor)
        } else {
            let toEliminate = Array(wrongColors.shuffled().prefix(1))
            return .eliminateFromPosition(position: bestPos, colors: toEliminate)
        }
    }

    private func applyDeduction(_ deduction: HintDeduction) {
        switch deduction {
        case .eliminateFromPosition(let pos, let colors):
            hintedPositions.insert(pos)
            for color in colors {
                notes[pos][color] = .eliminated
            }
            lastHintMessage = "P\(pos + 1): eliminated \(colors.count) colors"
            selectedSlot = pos

        case .confirmPosition(let pos, let color):
            hintedPositions.insert(pos)
            for c in availableColors {
                notes[pos][c] = (c == color) ? .confirmed : .eliminated
            }
            currentGuess[pos] = color
            lastHintMessage = "P\(pos + 1): confirmed!"
            if pos + 1 < codeLength {
                selectedSlot = pos + 1
            }
        }
    }

    func selectColor(_ color: PegColor) {
        guard phase == .playing, selectedSlot < codeLength else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            currentGuess[selectedSlot] = color
        }
        if selectedSlot < codeLength - 1 {
            selectedSlot += 1
        }
    }

    func tapSlot(_ index: Int) {
        guard phase == .playing else { return }
        selectedSlot = index
    }

    func clearSlot(_ index: Int) {
        guard phase == .playing else { return }
        withAnimation(.spring(response: 0.2)) {
            currentGuess[index] = nil
            selectedSlot = index
        }
    }

    func submitGuess() {
        let guess = currentGuess.compactMap { $0 }
        guard guess.count == codeLength, phase == .playing else {
            triggerShake()
            return
        }

        let feedback = engine.evaluate(guess: guess)
        let record = GuessRecord(guess: guess, feedback: feedback)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            guessHistory.append(record)
            currentGuess = Array(repeating: nil, count: codeLength)
            selectedSlot = 0
            
        }

        if feedback.isWin(codeLength: codeLength) {
            stopTimer()
            let attempts = guessHistory.count
            withAnimation(.spring(response: 0.5)) {
                phase = .won(attempts: attempts)
                showSecret = true
            }
            StatsManager.shared.recordWin(attempts: attempts)
            HintCoinManager.shared.recordWin()
            if isDailyChallenge {
                let elapsed = Int(Date().timeIntervalSince(gameStartTime ?? Date()))
                GameCenterManager.shared.submitDailyScore(
                    attempts: attempts,
                    maxAttempts: maxAttempts,
                    elapsedSeconds: elapsed
                )
            }
            switch mode {
            case .campaign(let levelId):
                let pm = (engine?.lieMode == true) ? ProgressManager.lieShared : ProgressManager.shared
                pm.complete(level: levelId, attempts: attempts, maxAttempts: maxAttempts)
            case .freePlay:
                if UserDefaults.standard.bool(forKey: "ach_daily_active") {
                    AchievementManager.shared.markDailyWin()
                    UserDefaults.standard.set(false, forKey: "ach_daily_active")
                } else {
                    AchievementManager.shared.markFreePlayWin()
                }
                if lastDifficulty == .master { UserDefaults.standard.set(true, forKey: "ach_free_master") }
                if lastDifficulty == .expert { UserDefaults.standard.set(true, forKey: "ach_free_expert") }
            case .duel:
                AchievementManager.shared.markDuelWin()
            }
        } else if guessHistory.count >= maxAttempts {
            stopTimer()
            StatsManager.shared.recordLoss()
            withAnimation(.spring(response: 0.5)) {
                phase = .lost
                showSecret = true
            }
        }
    }

    

    private func triggerShake() {
        shakeGuessRow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shakeGuessRow = false
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .playing else {
                    self?.stopTimer()
                    return
                }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.stopTimer()
                    withAnimation {
                        self.phase = .lost
                        self.showSecret = true
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func generateShareText() -> String {
        guard phase != .playing else { return "" }
        let won = phase != .lost
        let title: String
        if let level = level {
            title = "Code Breaker Level \(level.id)"
        } else {
            title = "Code Breaker Free Play"
        }

        var lines = [title]
        if won, case .won(let a) = phase {
            lines.append("Solved in \(a)/\(maxAttempts)")
        } else {
            lines.append("❌ Failed")
        }
        lines.append("")

        for record in guessHistory {
            var row = ""
            for i in 0..<record.guess.count {
                if record.guess[i] == secretCode[i] {
                    row += "🟢"
                } else if secretCode.contains(record.guess[i]) {
                    row += "🟡"
                } else {
                    row += "⚫"
                }
            }
            lines.append(row)
        }
        lines.append("")
        lines.append("🔐 Can you crack it?")
        return lines.joined(separator: "\n")
    }
}
