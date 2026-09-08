import Foundation

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

enum PegColor: Int, CaseIterable, Codable, Identifiable {
    case red, green, blue, yellow, purple, orange, cyan, pink

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .cyan: return "Cyan"
        case .pink: return "Pink"
        }
    }

    var symbol: String {
        switch self {
        case .red: return "1"
        case .green: return "2"
        case .blue: return "3"
        case .yellow: return "4"
        case .purple: return "5"
        case .orange: return "6"
        case .cyan: return "7"
        case .pink: return "8"
        }
    }
}

struct Feedback: Equatable {
    let exact: Int
    let partial: Int
    let isLie: Bool

    init(exact: Int, partial: Int, isLie: Bool = false) {
        self.exact = exact
        self.partial = partial
        self.isLie = isLie
    }

    func isWin(codeLength: Int) -> Bool { exact == codeLength && !isLie }
    var total: Int { exact + partial }
}

class GameEngine {
    let secretCode: [PegColor]
    let codeLength: Int
    let availableColors: [PegColor]
    let maxAttempts: Int
    let lieMode: Bool
    let seed: UInt64
    private(set) var lieUsed: Bool = false
    private(set) var lieAtGuess: Int? = nil
    private var guessCount: Int = 0
    private let lieAttemptNumber: Int?
    private var rng: SeededRNG

    init(codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false, forcedLieAttempt: Int? = nil) {
        let seed = UInt64.random(in: 1...UInt64.max)
        self.seed = seed
        self.codeLength = codeLength
        self.maxAttempts = maxAttempts
        self.lieMode = lieMode
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))

        var rng = SeededRNG(seed: seed)
        self.lieAttemptNumber = Self.resolvedLieAttempt(rng: &rng, codeLength: codeLength, lieMode: lieMode, forced: forcedLieAttempt)

        if allowDuplicates {
            self.secretCode = (0..<codeLength).map { _ in
                PegColor.allCases[Int(rng.next() % UInt64(colorCount))]
            }
        } else {
            var pool = Array(PegColor.allCases.prefix(colorCount))
            var code: [PegColor] = []
            for _ in 0..<codeLength {
                let idx = Int(rng.next() % UInt64(pool.count))
                code.append(pool.remove(at: idx))
            }
            self.secretCode = code
        }
        self.rng = rng
    }

    init(seed: UInt64, codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false, forcedLieAttempt: Int? = nil) {
        self.seed = seed
        self.codeLength = codeLength
        self.maxAttempts = maxAttempts
        self.lieMode = lieMode
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))

        var rng = SeededRNG(seed: seed)
        self.lieAttemptNumber = Self.resolvedLieAttempt(rng: &rng, codeLength: codeLength, lieMode: lieMode, forced: forcedLieAttempt)

        if allowDuplicates {
            self.secretCode = (0..<codeLength).map { _ in
                PegColor.allCases[Int(rng.next() % UInt64(colorCount))]
            }
        } else {
            var pool = Array(PegColor.allCases.prefix(colorCount))
            var code: [PegColor] = []
            for _ in 0..<codeLength {
                let idx = Int(rng.next() % UInt64(pool.count))
                code.append(pool.remove(at: idx))
            }
            self.secretCode = code
        }
        self.rng = rng
    }

    init(secretCode: [PegColor], colorCount: Int, maxAttempts: Int) {
        self.secretCode = secretCode
        self.codeLength = secretCode.count
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))
        self.maxAttempts = maxAttempts
        self.lieMode = false
        self.lieAttemptNumber = nil
        self.seed = 0
        self.rng = SeededRNG(seed: 0)
    }

    private static func resolvedLieAttempt(rng: inout SeededRNG, codeLength: Int, lieMode: Bool, forced: Int?) -> Int? {
        guard lieMode else { return nil }
        if let forced { return max(1, forced) }
        let optimalSteps: Int
        switch codeLength {
        case 3: optimalSteps = 4
        case 4: optimalSteps = 6
        case 5: optimalSteps = 8
        default: optimalSteps = 8
        }
        return Int(rng.next() % UInt64(max(1, optimalSteps - 1))) + 1
    }

    func evaluate(guess: [PegColor]) -> Feedback {
        guard guess.count == codeLength else {
            return Feedback(exact: 0, partial: 0)
        }

        guessCount += 1
        let realFeedback = computeRealFeedback(guess: guess)

        if lieMode && !lieUsed && guessCount == lieAttemptNumber && !realFeedback.isWin(codeLength: codeLength) {
            lieUsed = true
            lieAtGuess = guessCount
            return generateLie(real: realFeedback)
        }

        return realFeedback
    }

    func computeRealFeedback(guess: [PegColor]) -> Feedback {
        var exact = 0
        var secretRemaining: [PegColor] = []
        var guessRemaining: [PegColor] = []

        for i in 0..<codeLength {
            if guess[i] == secretCode[i] {
                exact += 1
            } else {
                secretRemaining.append(secretCode[i])
                guessRemaining.append(guess[i])
            }
        }

        var partial = 0
        var secretPool = secretRemaining
        for color in guessRemaining {
            if let idx = secretPool.firstIndex(of: color) {
                partial += 1
                secretPool.remove(at: idx)
            }
        }

        return Feedback(exact: exact, partial: partial)
    }

    private func generateLie(real: Feedback) -> Feedback {
        var options: [Feedback] = []
        for e in 0...codeLength {
            for p in 0...(codeLength - e) {
                let f = Feedback(exact: e, partial: p, isLie: true)
                if f != Feedback(exact: real.exact, partial: real.partial) {
                    options.append(f)
                }
            }
        }
        let close = options.filter {
            abs($0.exact - real.exact) <= 1 && abs($0.partial - real.partial) <= 1
        }
        let pool = close.isEmpty ? options : close
        guard !pool.isEmpty else {
            return Feedback(exact: max(0, real.exact - 1), partial: real.partial, isLie: true)
        }
        let idx = Int(rng.next() % UInt64(pool.count))
        return pool[idx]
    }
}
