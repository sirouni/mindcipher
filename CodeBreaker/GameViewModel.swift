import SwiftUI
import Combine

enum GamePhase: Equatable {
    case playing
    case won(attempts: Int)
    case lost
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var engine: GameEngine!
    @Published var guessHistory: [GuessRecord] = []
    @Published var currentGuess: [PegColor?] = []
    @Published var phase: GamePhase = .playing
    @Published var selectedSlot: Int = 0
    @Published var hintUsed: Bool = false
    @Published var showSecret: Bool = false
    @Published var timeRemaining: Int = 0
    @Published var shakeGuessRow: Bool = false
    @Published var undoAvailable: Bool = false

    var mode: GameMode = .freePlay
    var level: Level?
    var lastDifficulty: Difficulty = .easy
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

    private func resetState() {
        guessHistory = []
        currentGuess = Array(repeating: nil, count: codeLength)
        phase = .playing
        selectedSlot = 0
        hintUsed = false
        showSecret = false
        shakeGuessRow = false
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

    func undoLastGuess() {
        guard phase == .playing, !guessHistory.isEmpty, undoAvailable else { return }
        withAnimation(.spring(response: 0.3)) {
            let last = guessHistory.removeLast()
            currentGuess = last.guess.map { Optional($0) }
            selectedSlot = codeLength - 1
            undoAvailable = false
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
            undoAvailable = true
        }

        if feedback.isWin(codeLength: codeLength) {
            stopTimer()
            let attempts = guessHistory.count
            withAnimation(.spring(response: 0.5)) {
                phase = .won(attempts: attempts)
                showSecret = true
            }
            StatsManager.shared.recordWin(attempts: attempts)
            if case .campaign(let levelId) = mode {
                let pm = (engine?.lieMode == true) ? ProgressManager.lieShared : ProgressManager.shared
                pm.complete(
                    level: levelId,
                    attempts: attempts,
                    maxAttempts: maxAttempts
                )
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

    func useHint() -> String? {
        guard phase == .playing, !hintUsed else { return nil }
        hintUsed = true

        let unguessedPositions = (0..<codeLength).filter { pos in
            !guessHistory.contains { $0.guess[pos] == secretCode[pos] }
        }
        guard let pos = unguessedPositions.randomElement() else { return nil }
        let color = secretCode[pos]
        return "位置 \(pos + 1) 的颜色是\(color.displayName)色"
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
            title = "密码破译局 关卡\(level.id)"
        } else {
            title = "密码破译局 自由模式"
        }

        var lines = [title]
        if won, case .won(let a) = phase {
            lines.append("✅ \(a)/\(maxAttempts) 步破译")
        } else {
            lines.append("❌ 破译失败")
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
        lines.append("🔐 来挑战？")
        return lines.joined(separator: "\n")
    }
}
