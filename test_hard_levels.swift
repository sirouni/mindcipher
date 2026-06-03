#!/usr/bin/env swift

// 高难度关卡可解性验证 - 信息熵贪心求解器
// 验证困难/专家/大师关卡在限定步数内可解
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
        if guess[i] == secret[i] { exact += 1 } else { sR.append(secret[i]); gR.append(guess[i]) }
    }
    var partial = 0; var pool = sR
    for c in gR { if let i = pool.firstIndex(of: c) { partial += 1; pool.remove(at: i) } }
    return Feedback(exact: exact, partial: partial)
}

// 生成所有可能密码
func generateAll(codeLen: Int, colorCount: Int, allowDup: Bool) -> [[PegColor]] {
    let colors = Array(PegColor.allCases.prefix(colorCount))
    var results: [[PegColor]] = []

    if allowDup {
        func gen(_ current: [PegColor]) {
            if current.count == codeLen { results.append(current); return }
            for c in colors { gen(current + [c]) }
        }
        gen([])
    } else {
        func gen(_ current: [PegColor], _ remaining: [PegColor]) {
            if current.count == codeLen { results.append(current); return }
            for (i, c) in remaining.enumerated() {
                var r = remaining; r.remove(at: i)
                gen(current + [c], r)
            }
        }
        gen([], colors)
    }
    return results
}

// 信息熵贪心求解：选择使反馈分区最均匀的猜测（近似最优）
func solveEntropy(secret: [PegColor], allCandidates: [[PegColor]], maxAttempts: Int) -> Int? {
    var candidates = allCandidates
    let codeLen = secret.count

    for attempt in 1...maxAttempts {
        if candidates.count <= 1 {
            let fb = evaluate(guess: candidates[0], secret: secret)
            return fb.isWin(codeLen) ? attempt : nil
        }

        // 选最佳猜测：从候选中挑一个使最大分区最小的
        let guess: [PegColor]
        if attempt == 1 && candidates.count > 1000 {
            // 首猜用固定策略加速（不遍历所有候选）
            guess = candidates[0]
        } else if candidates.count > 500 {
            // 候选太多时从抽样中选
            let sample = Array(candidates.prefix(min(50, candidates.count)))
            guess = bestGuess(from: sample, candidates: candidates, codeLen: codeLen)
        } else {
            guess = bestGuess(from: candidates, candidates: candidates, codeLen: codeLen)
        }

        let fb = evaluate(guess: guess, secret: secret)
        if fb.isWin(codeLen) { return attempt }

        // 过滤候选
        candidates = candidates.filter { evaluate(guess: guess, secret: $0) == fb }
    }
    return nil
}

// 选最佳猜测：使得反馈分区中最大桶最小（minimax 思想）
func bestGuess(from options: [[PegColor]], candidates: [[PegColor]], codeLen: Int) -> [PegColor] {
    var bestGuessCode = options[0]
    var bestWorst = candidates.count

    for g in options {
        var buckets: [Feedback: Int] = [:]
        for c in candidates {
            let fb = evaluate(guess: g, secret: c)
            buckets[fb, default: 0] += 1
        }
        let worst = buckets.values.max() ?? 0
        if worst < bestWorst {
            bestWorst = worst
            bestGuessCode = g
        }
    }
    return bestGuessCode
}

// ============ 测试配置 ============

struct TestConfig {
    let name: String
    let codeLen: Int
    let colorCount: Int
    let maxAttempts: Int
    let allowDup: Bool
    let sampleSize: Int // 抽样测试数
}

let configs: [TestConfig] = [
    TestConfig(name: "困难 (5位7色重复)", codeLen: 5, colorCount: 7, maxAttempts: 8, allowDup: true, sampleSize: 50),
    TestConfig(name: "专家 (5位8色重复)", codeLen: 5, colorCount: 8, maxAttempts: 9, allowDup: true, sampleSize: 50),
    TestConfig(name: "大师 (6位8色重复)", codeLen: 6, colorCount: 8, maxAttempts: 10, allowDup: true, sampleSize: 30),
]

// ============ 执行 ============

print("🔐 高难度关卡可解性验证 - 信息熵贪心求解器")
print(String(repeating: "=", count: 55))
print("")

var allPassed = true

for config in configs {
    print("📋 \(config.name)")
    print("   配置: \(config.codeLen)位 \(config.colorCount)色 最多\(config.maxAttempts)步 重复=\(config.allowDup)")

    let allCodes = generateAll(codeLen: config.codeLen, colorCount: config.colorCount, allowDup: config.allowDup)
    print("   总组合数: \(allCodes.count)")

    // 随机抽样
    let sample = Array(allCodes.shuffled().prefix(config.sampleSize))
    print("   测试样本: \(sample.count) 个密码")

    var solved = 0
    var maxSteps = 0
    var totalSteps = 0
    var failedCodes: [[PegColor]] = []

    let startTime = Date()

    for (i, secret) in sample.enumerated() {
        if let steps = solveEntropy(secret: secret, allCandidates: allCodes, maxAttempts: config.maxAttempts) {
            solved += 1
            maxSteps = max(maxSteps, steps)
            totalSteps += steps
        } else {
            failedCodes.append(secret)
        }

        // 进度
        if (i + 1) % 10 == 0 {
            let elapsed = Date().timeIntervalSince(startTime)
            print("   ... \(i+1)/\(sample.count) (已用\(String(format: "%.1f", elapsed))秒)")
        }
    }

    let elapsed = Date().timeIntervalSince(startTime)
    print("   ⏱  耗时: \(String(format: "%.1f", elapsed))秒")
    print("   ✅ 可解: \(solved)/\(sample.count)")
    print("   📊 最难步数: \(maxSteps)")
    print("   📊 平均步数: \(String(format: "%.2f", Double(totalSteps) / Double(max(1, solved))))")

    if !failedCodes.isEmpty {
        allPassed = false
        print("   ❌ 失败样本: \(failedCodes.count) 个")
        for code in failedCodes.prefix(3) {
            print("      \(code.map { "\($0)" })")
        }
    }
    print("")
}

print(String(repeating: "=", count: 55))
if allPassed {
    print("🎉 全部高难度关卡验证通过！所有抽样密码均可在限定步数内解出。")
} else {
    print("⚠️  存在不可解情况，需要增加步数上限或调整参数。")
}
