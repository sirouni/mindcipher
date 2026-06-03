#!/usr/bin/env swift

// 谎言模式可解性测试 — 验证"知道有1次谎言"时仍能在限定步数内解出
import Foundation

enum PegColor: Int, CaseIterable { case red, green, blue, yellow, purple, orange, cyan, pink }

struct Feedback: Hashable {
    let exact: Int; let partial: Int; let isLie: Bool
    init(exact: Int, partial: Int, isLie: Bool = false) {
        self.exact = exact; self.partial = partial; self.isLie = isLie
    }
    func isWin(_ len: Int) -> Bool { exact == len && !isLie }
    var truthOnly: Feedback { Feedback(exact: exact, partial: partial) }
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

func generateAll(codeLen: Int, colorCount: Int, allowDup: Bool) -> [[PegColor]] {
    let colors = Array(PegColor.allCases.prefix(colorCount))
    var results: [[PegColor]] = []
    if allowDup {
        func gen(_ curr: [PegColor]) {
            if curr.count == codeLen { results.append(curr); return }
            for c in colors { gen(curr + [c]) }
        }
        gen([])
    } else {
        func gen(_ curr: [PegColor], _ rem: [PegColor]) {
            if curr.count == codeLen { results.append(curr); return }
            for (i, c) in rem.enumerated() {
                var r = rem; r.remove(at: i)
                gen(curr + [c], r)
            }
        }
        gen([], colors)
    }
    return results
}

// 谎言模式求解器：
// 策略：维护候选集，但允许"排除1条反馈后仍一致"的候选
func solveLieMode(secret: [PegColor], allCandidates: [[PegColor]], maxAttempts: Int, lieAtGuess: Int) -> Int? {
    let codeLen = secret.count
    var guesses: [(guess: [PegColor], feedback: Feedback)] = []
    var candidates = allCandidates

    for attempt in 1...maxAttempts {
        if candidates.isEmpty { return nil }
        if candidates.count == 1 {
            let fb = evaluate(guess: candidates[0], secret: secret)
            if attempt == lieAtGuess {
                // 这步是谎言，但我们直接猜了正确答案——代码保证不在猜对时撒谎
                if fb.isWin(codeLen) { return attempt }
            } else {
                if fb.isWin(codeLen) { return attempt }
            }
        }

        // 选猜测：用第一个候选（简化策略）
        let guess = candidates[0]
        let realFb = evaluate(guess: guess, secret: secret)

        // 模拟谎言：在指定步骤给假反馈
        let receivedFb: Feedback
        if attempt == lieAtGuess && !realFb.isWin(codeLen) {
            // 生成一个接近真实值的假反馈
            var lie = realFb
            let delta = [-1, 1].randomElement()!
            let newExact = max(0, min(codeLen, realFb.exact + delta))
            let newPartial = max(0, min(codeLen - newExact, realFb.partial + (delta == 1 ? -1 : 0)))
            lie = Feedback(exact: newExact, partial: newPartial, isLie: true)
            if lie.exact == realFb.exact && lie.partial == realFb.partial {
                lie = Feedback(exact: max(0, realFb.exact - 1), partial: min(codeLen - realFb.exact + 1, realFb.partial + 1), isLie: true)
            }
            receivedFb = lie
        } else {
            receivedFb = realFb
        }

        if receivedFb.isWin(codeLen) { return attempt }

        guesses.append((guess, receivedFb))

        // 聪明的过滤策略：一个候选有效 = 存在某种方式排除最多1条反馈后，所有其余反馈一致
        candidates = candidates.filter { candidate in
            // 检查：如果去掉第 k 条反馈，其余是否全部一致
            for skipIdx in -1..<guesses.count { // -1 = 不跳过任何
                var consistent = true
                for (i, record) in guesses.enumerated() {
                    if i == skipIdx { continue }
                    let simFb = evaluate(guess: record.guess, secret: candidate)
                    if simFb.exact != record.feedback.exact || simFb.partial != record.feedback.partial {
                        consistent = false
                        break
                    }
                }
                if consistent { return true }
            }
            return false
        }
    }
    return nil
}

// ============ 测试 ============

print("🎭 谎言模式可解性测试")
print(String(repeating: "=", count: 55))

struct TestConfig {
    let name: String; let codeLen: Int; let colors: Int; let baseAttempts: Int
    let extraAttempts: Int; let allowDup: Bool; let samples: Int
}

let configs: [TestConfig] = [
    TestConfig(name: "新手+谎言 (3位4色)", codeLen: 3, colors: 4, baseAttempts: 10, extraAttempts: 3, allowDup: false, samples: 24),
    TestConfig(name: "简单+谎言 (4位6色)", codeLen: 4, colors: 6, baseAttempts: 8, extraAttempts: 3, allowDup: false, samples: 30),
]

var allPassed = true

for config in configs {
    print("\n📋 \(config.name)")
    let totalAttempts = config.baseAttempts + config.extraAttempts
    print("   步数: \(config.baseAttempts) + \(config.extraAttempts)额外 = \(totalAttempts)")

    let allCodes = generateAll(codeLen: config.codeLen, colorCount: config.colors, allowDup: config.allowDup)
    print("   总密码数: \(allCodes.count)")

    let sample = Array(allCodes.shuffled().prefix(config.samples))
    var solved = 0; var maxSteps = 0; var failed = 0

    for secret in sample {
        // 谎言可能出现在任何步骤（1 到 maxAttempts-2）
        let lieAt = Int.random(in: 1...max(1, totalAttempts - 2))
        if let steps = solveLieMode(secret: secret, allCandidates: allCodes, maxAttempts: totalAttempts, lieAtGuess: lieAt) {
            solved += 1
            maxSteps = max(maxSteps, steps)
        } else {
            failed += 1
        }
    }

    print("   ✅ 可解: \(solved)/\(sample.count)")
    print("   ❌ 失败: \(failed)/\(sample.count)")
    print("   📊 最难步数: \(maxSteps)/\(totalAttempts)")

    if failed > 0 { allPassed = false }
}

// 对比测试：不加额外步数
print("\n" + String(repeating: "-", count: 55))
print("📋 对比: 简单+谎言 无额外步数 (4位6色, 仅8步)")
let allCodes4 = generateAll(codeLen: 4, colorCount: 6, allowDup: false)
let sample = Array(allCodes4.shuffled().prefix(30))
var solvedNoExtra = 0; var failedNoExtra = 0

for secret in sample {
    let lieAt = Int.random(in: 1...6)
    if let _ = solveLieMode(secret: secret, allCandidates: allCodes4, maxAttempts: 8, lieAtGuess: lieAt) {
        solvedNoExtra += 1
    } else {
        failedNoExtra += 1
    }
}
print("   仅8步可解: \(solvedNoExtra)/\(sample.count)")
print("   失败: \(failedNoExtra)/\(sample.count)")
if failedNoExtra > 0 {
    print("   ⚠️  不加额外步数时有失败! 证明+3步是必要的")
}

print("\n" + String(repeating: "=", count: 55))
if allPassed {
    print("🎉 加3步后谎言模式全部可解！设计合理。")
} else {
    print("⚠️  仍有不可解情况，需要进一步调整。")
}
