#!/usr/bin/env swift

// Standalone test: validates all 480 levels (240 classic + 240 lie) are solvable
// Run: swift test_all_levels.swift

import Foundation

// MARK: - Minimal copies of game types for standalone testing

enum PegColor: Int, CaseIterable {
    case red, green, blue, yellow, purple, orange, cyan, pink
}

struct Feedback: Equatable {
    let exact: Int
    let partial: Int
    let isLie: Bool
    init(exact: Int, partial: Int, isLie: Bool = false) {
        self.exact = exact; self.partial = partial; self.isLie = isLie
    }
    func isWin(codeLength: Int) -> Bool { exact == codeLength && !isLie }
}

class GameEngine {
    let secretCode: [PegColor]
    let codeLength: Int
    let availableColors: [PegColor]
    let maxAttempts: Int
    let lieMode: Bool
    private(set) var lieUsed = false
    private(set) var lieAtGuess: Int?
    private var guessCount = 0
    private let lieAttemptNumber: Int?

    init(codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false) {
        self.codeLength = codeLength
        self.maxAttempts = maxAttempts
        self.lieMode = lieMode
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))
        if lieMode {
            let opt: Int
            switch codeLength { case 3: opt = 4; case 4: opt = 6; case 5: opt = 8; default: opt = 8 }
            self.lieAttemptNumber = Int.random(in: 1...max(1, opt - 1))
        } else { self.lieAttemptNumber = nil }
        if allowDuplicates {
            self.secretCode = (0..<codeLength).map { _ in PegColor.allCases[Int.random(in: 0..<colorCount)] }
        } else {
            var pool = Array(PegColor.allCases.prefix(colorCount))
            var code: [PegColor] = []
            for _ in 0..<codeLength { let idx = Int.random(in: 0..<pool.count); code.append(pool.remove(at: idx)) }
            self.secretCode = code
        }
    }

    func evaluate(guess: [PegColor]) -> Feedback {
        guessCount += 1
        let real = computeRealFeedback(guess: guess)
        if lieMode && !lieUsed && guessCount == lieAttemptNumber && !real.isWin(codeLength: codeLength) {
            lieUsed = true; lieAtGuess = guessCount
            return generateLie(real: real)
        }
        return real
    }

    func computeRealFeedback(guess: [PegColor]) -> Feedback {
        var exact = 0; var sR: [PegColor] = []; var gR: [PegColor] = []
        for i in 0..<codeLength {
            if guess[i] == secretCode[i] { exact += 1 } else { sR.append(secretCode[i]); gR.append(guess[i]) }
        }
        var partial = 0; var pool = sR
        for c in gR { if let idx = pool.firstIndex(of: c) { partial += 1; pool.remove(at: idx) } }
        return Feedback(exact: exact, partial: partial)
    }

    private func generateLie(real: Feedback) -> Feedback {
        var opts: [Feedback] = []
        for e in 0...codeLength { for p in 0...(codeLength - e) {
            let f = Feedback(exact: e, partial: p, isLie: true)
            if f.exact != real.exact || f.partial != real.partial { opts.append(f) }
        }}
        let close = opts.filter { abs($0.exact - real.exact) <= 1 && abs($0.partial - real.partial) <= 1 }
        return (close.isEmpty ? opts : close).randomElement() ?? Feedback(exact: max(0, real.exact - 1), partial: real.partial, isLie: true)
    }
}

// MARK: - Level config

enum Difficulty: String, CaseIterable {
    case beginner = "Beginner", easy = "Easy", medium = "Medium"
    case hard = "Hard", expert = "Expert", master = "Master"

    var codeLength: Int { switch self { case .beginner: 3; case .easy: 3; case .medium: 4; case .hard: 5; case .expert: 5; case .master: 6 } }
    var colorCount: Int { switch self { case .beginner: 4; case .easy: 4; case .medium: 6; case .hard: 6; case .expert: 8; case .master: 8 } }
    var maxAttempts: Int { switch self { case .beginner: 10; case .easy: 9; case .medium: 9; case .hard: 10; case .expert: 12; case .master: 14 } }
    var allowDuplicates: Bool { switch self { case .beginner, .easy, .medium: false; default: true } }
    var lieExtraAttempts: Int { switch self { case .beginner: 5; case .easy: 7; case .medium: 8; case .hard: 7; case .expert: 7; case .master: 5 } }
}

struct Level {
    let id: Int; let diff: Difficulty; let codeLength: Int; let colorCount: Int
    let maxAttempts: Int; let allowDuplicates: Bool
}

// MARK: - Solver

func simulateFeedback(guess: [PegColor], secret: [PegColor]) -> (Int, Int) {
    let len = guess.count
    var exact = 0; var sR: [PegColor] = []; var gR: [PegColor] = []
    for i in 0..<len { if guess[i] == secret[i] { exact += 1 } else { sR.append(secret[i]); gR.append(guess[i]) } }
    var partial = 0; var pool = sR
    for c in gR { if let idx = pool.firstIndex(of: c) { partial += 1; pool.remove(at: idx) } }
    return (exact, partial)
}

func solve(engine: GameEngine) -> Bool {
    let colors = engine.availableColors
    let len = engine.codeLength
    var allGuesses: [[PegColor]] = []

    func gen(_ cur: [PegColor]) {
        if cur.count == len { allGuesses.append(cur); return }
        for c in colors { gen(cur + [c]) }
    }
    gen([])

    var candidates = allGuesses
    var history: [(guess: [PegColor], exact: Int, partial: Int)] = []

    for _ in 0..<engine.maxAttempts {
        if candidates.isEmpty {
            if engine.lieMode && !history.isEmpty {
                for skipIdx in 0..<history.count {
                    var rebuilt = allGuesses
                    for (i, h) in history.enumerated() {
                        if i == skipIdx { continue }
                        rebuilt = rebuilt.filter { c in
                            let (e, p) = simulateFeedback(guess: h.guess, secret: c)
                            return e == h.exact && p == h.partial
                        }
                    }
                    if !rebuilt.isEmpty { candidates = rebuilt; break }
                }
            }
            if candidates.isEmpty { return false }
        }
        let guess = candidates[0]
        let fb = engine.evaluate(guess: guess)
        if fb.isWin(codeLength: len) { return true }
        history.append((guess, fb.exact, fb.partial))
        candidates = candidates.filter { c in
            let (e, p) = simulateFeedback(guess: guess, secret: c)
            return e == fb.exact && p == fb.partial
        }
    }
    return false
}

// MARK: - Generate levels

func generateLevels() -> [Level] {
    let minAttempts: [Difficulty: Int] = [
        .beginner: 8, .easy: 8, .medium: 8,
        .hard: 9, .expert: 10, .master: 12,
    ]
    var levels: [Level] = []
    var id = 1
    for diff in Difficulty.allCases {
        let floor = minAttempts[diff] ?? (diff.codeLength + 2)
        for j in 0..<40 {
            let progress = Double(j) / 40.0
            var attempts = diff.maxAttempts
            if progress > 0.5 { attempts -= 1 }
            if progress > 0.8 { attempts -= 1 }
            attempts = max(attempts, floor)
            levels.append(Level(id: id, diff: diff, codeLength: diff.codeLength, colorCount: diff.colorCount,
                                maxAttempts: attempts, allowDuplicates: diff.allowDuplicates))
            id += 1
        }
    }
    return levels
}

// MARK: - Run tests

let levels = generateLevels()
var totalTests = 0
var passed = 0
var failed = 0
let trialsPerLevel = 3

print("Testing \(levels.count) classic levels × \(trialsPerLevel) trials...")
print("=" * 60)

for level in levels {
    var levelOk = true
    for trial in 0..<trialsPerLevel {
        let engine = GameEngine(
            codeLength: level.codeLength, colorCount: level.colorCount,
            allowDuplicates: level.allowDuplicates, maxAttempts: level.maxAttempts
        )
        totalTests += 1
        if solve(engine: engine) {
            passed += 1
        } else {
            failed += 1; levelOk = false
            print("  FAIL: Classic Level \(level.id) (\(level.diff.rawValue)) trial \(trial+1) — " +
                  "code=\(level.codeLength) colors=\(level.colorCount) attempts=\(level.maxAttempts) dups=\(level.allowDuplicates)")
        }
    }
    if levelOk && level.id % 40 == 0 {
        print("  Tier \(level.id / 40) (\(level.diff.rawValue)) — 40 levels × \(trialsPerLevel) trials: ALL PASSED")
    }
}

print("\nTesting \(levels.count) lie mode levels × \(trialsPerLevel) trials...")
print("=" * 60)

for level in levels {
    var levelOk = true
    let totalAttempts = level.maxAttempts + level.diff.lieExtraAttempts
    for trial in 0..<trialsPerLevel {
        let engine = GameEngine(
            codeLength: level.codeLength, colorCount: level.colorCount,
            allowDuplicates: level.allowDuplicates, maxAttempts: totalAttempts, lieMode: true
        )
        totalTests += 1
        if solve(engine: engine) {
            passed += 1
        } else {
            failed += 1; levelOk = false
            print("  FAIL: Lie Level \(level.id) (\(level.diff.rawValue)) trial \(trial+1) — " +
                  "code=\(level.codeLength) colors=\(level.colorCount) attempts=\(totalAttempts) dups=\(level.allowDuplicates)")
        }
    }
    if levelOk && level.id % 40 == 0 {
        print("  Tier \(level.id / 40) (\(level.diff.rawValue)) — 40 levels × \(trialsPerLevel) trials: ALL PASSED")
    }
}

print("\n" + "=" * 60)
print("RESULTS: \(passed)/\(totalTests) passed, \(failed) failed")
if failed == 0 {
    print("ALL 480 LEVELS VALIDATED SUCCESSFULLY")
} else {
    print("WARNING: \(failed) failures detected!")
    exit(1)
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
