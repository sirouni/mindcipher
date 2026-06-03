#!/usr/bin/env swift

// 大师级谎言模式 - 最优求解器（完整 minimax + lie-aware）
// 验证在 16 步内是否 100% 可解
import Foundation

enum PegColor: Int, CaseIterable { case red, green, blue, yellow, purple, orange, cyan, pink }

struct Feedback: Hashable {
    let exact: Int; let partial: Int
    func isWin(_ len: Int) -> Bool { exact == len }
}

func evaluate(guess: [PegColor], secret: [PegColor]) -> Feedback {
    let n = secret.count
    var exact = 0; var sR: [PegColor] = []; var gR: [PegColor] = []
    for i in 0..<n {
        if guess[i] == secret[i] { exact += 1 }
        else { sR.append(secret[i]); gR.append(guess[i]) }
    }
    var partial = 0; var pool = sR
    for c in gR { if let i = pool.firstIndex(of: c) { partial += 1; pool.remove(at: i) } }
    return Feedback(exact: exact, partial: partial)
}

func generateAll(codeLen: Int, colorCount: Int) -> [[PegColor]] {
    let colors = Array(PegColor.allCases.prefix(colorCount))
    var results: [[PegColor]] = []
    func gen(_ curr: [PegColor]) {
        if curr.count == codeLen { results.append(curr); return }
        for c in colors { gen(curr + [c]) }
    }
    gen([])
    return results
}

// 核心：谎言感知过滤
// 一个候选密码 c 是"可能的" 当且仅当：存在某种方式跳过 ≤1 条历史反馈后，其余全部一致
func filterCandidates(_ candidates: [[PegColor]], history: [(guess: [PegColor], fb: Feedback)]) -> [[PegColor]] {
    return candidates.filter { cand in
        // 快速路径：全部一致
        var mismatches = 0
        for h in history {
            if evaluate(guess: h.guess, secret: cand) != h.fb { mismatches += 1 }
            if mismatches > 1 { break }
        }
        return mismatches <= 1  // 允许最多1条不一致（那就是谎言）
    }
}

// 最优猜测选择：信息熵最大化
// 选择使得"最坏情况下剩余候选数最小"的猜测（minimax）
func optimalGuess(candidates: [[PegColor]], allGuesses: [[PegColor]], codeLen: Int) -> [PegColor] {
    if candidates.count <= 2 { return candidates[0] }

    // 对于大候选集，从候选中抽样作为猜测选项
    let guessOptions: [[PegColor]]
    if candidates.count > 100 {
        guessOptions = Array(candidates.prefix(60))
    } else {
        guessOptions = candidates
    }

    var bestGuess = guessOptions[0]
    var bestScore = Int.max  // 最小化最大分区

    for g in guessOptions {
        var buckets: [Feedback: Int] = [:]
        for c in candidates {
            let fb = evaluate(guess: g, secret: c)
            buckets[fb, default: 0] += 1
        }
        // minimax: 看最大桶
        let worstBucket = buckets.values.max() ?? 0
        if worstBucket < bestScore {
            bestScore = worstBucket
            bestGuess = g
        } else if worstBucket == bestScore {
            // tie-break: 优先选候选中的（如果猜对了直接赢）
            if candidates.contains(where: { $0 == g }) && !candidates.contains(where: { $0 == bestGuess }) {
                bestGuess = g
            }
        }
    }
    return bestGuess
}

// 完整最优求解器
func solveOptimalLieAware(
    secret: [PegColor],
    allCandidates: [[PegColor]],
    maxAttempts: Int,
    lieAt: Int
) -> Int? {
    let codeLen = secret.count
    var history: [(guess: [PegColor], fb: Feedback)] = []
    var candidates = allCandidates

    for attempt in 1...maxAttempts {
        if candidates.isEmpty { return nil }

        // 选最优猜测
        let guess = optimalGuess(candidates: candidates, allGuesses: allCandidates, codeLen: codeLen)

        // 真实反馈
        let realFb = evaluate(guess: guess, secret: secret)

        // 模拟谎言
        let receivedFb: Feedback
        if attempt == lieAt && !realFb.isWin(codeLen) {
            receivedFb = makeLie(real: realFb, codeLen: codeLen)
        } else {
            receivedFb = realFb
        }

        if receivedFb.isWin(codeLen) { return attempt }

        history.append((guess, receivedFb))

        // 谎言感知过滤
        candidates = filterCandidates(candidates, history: history)
    }
    return nil
}

func makeLie(real: Feedback, codeLen: Int) -> Feedback {
    // 生成所有可能的"接近真实值"的假反馈
    var options: [Feedback] = []
    for de in -1...1 {
        for dp in -1...1 {
            if de == 0 && dp == 0 { continue }
            let e = real.exact + de; let p = real.partial + dp
            if e >= 0 && p >= 0 && e + p <= codeLen {
                options.append(Feedback(exact: e, partial: p))
            }
        }
    }
    return options.randomElement() ?? Feedback(exact: max(0, real.exact - 1), partial: real.partial)
}

// ============ 运行测试 ============

print("🧠 大师级谎言模式 — 最优求解器验证")
print(String(repeating: "=", count: 55))

// 先测困难级确认算法正确
print("\n📋 校验: 困难 (5位7色重复, +4步=12步)")
let allCodes5x7 = generateAll(codeLen: 5, colorCount: 7)
print("   候选数: \(allCodes5x7.count)")
let sample5x7 = Array(allCodes5x7.shuffled().prefix(20))
var solved5 = 0; var max5 = 0
let start5 = Date()
for secret in sample5x7 {
    let lieAt = Int.random(in: 1...10)
    if let steps = solveOptimalLieAware(secret: secret, allCandidates: allCodes5x7, maxAttempts: 12, lieAt: lieAt) {
        solved5 += 1; max5 = max(max5, steps)
    }
}
print("   结果: \(solved5)/20 可解, 最难\(max5)步 [\(String(format:"%.1f", Date().timeIntervalSince(start5)))s]")

// 专家级
print("\n📋 专家 (5位8色重复, +5步=14步)")
let allCodes5x8 = generateAll(codeLen: 5, colorCount: 8)
print("   候选数: \(allCodes5x8.count)")
let sample5x8 = Array(allCodes5x8.shuffled().prefix(15))
var solved5x8 = 0; var max5x8 = 0
let start5x8 = Date()
for secret in sample5x8 {
    let lieAt = Int.random(in: 1...12)
    if let steps = solveOptimalLieAware(secret: secret, allCandidates: allCodes5x8, maxAttempts: 14, lieAt: lieAt) {
        solved5x8 += 1; max5x8 = max(max5x8, steps)
    }
}
print("   结果: \(solved5x8)/15 可解, 最难\(max5x8)步 [\(String(format:"%.1f", Date().timeIntervalSince(start5x8)))s]")

// 大师级 - 核心测试
print("\n📋 大师 (6位8色重复, 测试 +5/+6/+7 步)")
let allCodes6x8 = generateAll(codeLen: 6, colorCount: 8)
print("   候选数: \(allCodes6x8.count)")

for extra in [5, 6, 7] {
    let maxAtt = 10 + extra
    let sample6 = Array(allCodes6x8.shuffled().prefix(10))
    var solved6 = 0; var max6 = 0
    let start6 = Date()
    for secret in sample6 {
        let lieAt = Int.random(in: 1...max(1, maxAtt - 2))
        if let steps = solveOptimalLieAware(secret: secret, allCandidates: allCodes6x8, maxAttempts: maxAtt, lieAt: lieAt) {
            solved6 += 1; max6 = max(max6, steps)
        }
    }
    let elapsed = Date().timeIntervalSince(start6)
    let status = solved6 == sample6.count ? "✅" : "⚠️"
    print("   +\(extra)步(\(maxAtt)步): \(status) \(solved6)/10 最难\(max6)步 [\(String(format:"%.1f", elapsed))s]")
}

print("\n" + String(repeating: "=", count: 55))
print("完成。请根据结果决定大师级谎言模式的最终步数。")
