#!/usr/bin/env swift

// 全难度谎言模式可解性测试
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

// 谎言感知求解器：维护候选集，允许排除1条反馈
func solveLieAware(secret: [PegColor], allCandidates: [[PegColor]], maxAttempts: Int, lieAt: Int) -> Int? {
    let codeLen = secret.count
    var history: [(guess: [PegColor], fb: Feedback)] = []
    var candidates = allCandidates

    for attempt in 1...maxAttempts {
        if candidates.isEmpty { return nil }

        // 选猜测
        let guess: [PegColor]
        if candidates.count == 1 {
            guess = candidates[0]
        } else if candidates.count > 200 {
            guess = candidates[0]
        } else {
            // minimax: 选最小最大分区的猜测
            guess = bestGuess(from: Array(candidates.prefix(30)), candidates: candidates, codeLen: codeLen)
        }

        // 计算真实反馈
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

        // 谎言感知过滤：候选有效 = 存在跳过≤1条反馈后全部一致
        candidates = candidates.filter { cand in
            // 先检查全部一致（快速路径）
            var allMatch = true
            for h in history {
                let fb = evaluate(guess: h.guess, secret: cand)
                if fb != h.fb { allMatch = false; break }
            }
            if allMatch { return true }

            // 尝试跳过1条
            for skip in 0..<history.count {
                var ok = true
                for (i, h) in history.enumerated() {
                    if i == skip { continue }
                    let fb = evaluate(guess: h.guess, secret: cand)
                    if fb != h.fb { ok = false; break }
                }
                if ok { return true }
            }
            return false
        }
    }
    return nil
}

func bestGuess(from options: [[PegColor]], candidates: [[PegColor]], codeLen: Int) -> [PegColor] {
    var best = options[0]; var bestWorst = candidates.count
    for g in options {
        var buckets: [Feedback: Int] = [:]
        for c in candidates { buckets[evaluate(guess: g, secret: c), default: 0] += 1 }
        let worst = buckets.values.max() ?? 0
        if worst < bestWorst { bestWorst = worst; best = g }
    }
    return best
}

func makeLie(real: Feedback, codeLen: Int) -> Feedback {
    let deltas = [(-1,0),(1,0),(0,-1),(0,1),(-1,1),(1,-1)]
    for (de, dp) in deltas.shuffled() {
        let e = real.exact + de; let p = real.partial + dp
        if e >= 0 && p >= 0 && e + p <= codeLen && (e != real.exact || p != real.partial) {
            return Feedback(exact: e, partial: p)
        }
    }
    return Feedback(exact: max(0, real.exact - 1), partial: real.partial)
}

// ============ 测试 ============

print("🎭 全难度谎言模式可解性测试")
print(String(repeating: "=", count: 55))

struct Config {
    let name: String; let codeLen: Int; let colors: Int; let baseAttempts: Int
    let allowDup: Bool; let samples: Int; let extraSteps: [Int]
}

let configs: [Config] = [
    Config(name: "中等 (4位6色)", codeLen: 4, colors: 6, baseAttempts: 7, allowDup: false, samples: 30, extraSteps: [2,3,4]),
    Config(name: "困难 (5位7色重复)", codeLen: 5, colors: 7, baseAttempts: 8, allowDup: true, samples: 20, extraSteps: [3,4,5]),
    Config(name: "专家 (5位8色重复)", codeLen: 5, colors: 8, baseAttempts: 9, allowDup: true, samples: 15, extraSteps: [3,4,5]),
    Config(name: "大师 (6位8色重复)", codeLen: 6, colors: 8, baseAttempts: 10, allowDup: true, samples: 10, extraSteps: [3,4,5,6]),
]

var recommendations: [(String, Int)] = []

for config in configs {
    print("\n📋 \(config.name)")
    print("   基础步数: \(config.baseAttempts)")

    let allCodes = generateAll(codeLen: config.codeLen, colorCount: config.colors, allowDup: config.allowDup)
    print("   候选数: \(allCodes.count), 抽样: \(config.samples)")

    let secrets = Array(allCodes.shuffled().prefix(config.samples))
    var bestExtra = config.extraSteps.last!

    for extra in config.extraSteps {
        let total = config.baseAttempts + extra
        var solved = 0; var maxSteps = 0

        let start = Date()
        for secret in secrets {
            let lieAt = Int.random(in: 1...max(1, total - 2))
            if let steps = solveLieAware(secret: secret, allCandidates: allCodes, maxAttempts: total, lieAt: lieAt) {
                solved += 1; maxSteps = max(maxSteps, steps)
            }
        }
        let elapsed = Date().timeIntervalSince(start)

        let rate = Double(solved) / Double(config.samples) * 100
        let status = solved == config.samples ? "✅" : "⚠️"
        print("   +\(extra)步(\(total)步): \(status) \(solved)/\(config.samples) (\(String(format:"%.0f",rate))%) 最难\(maxSteps)步 [\(String(format:"%.1f",elapsed))s]")

        if solved == config.samples && extra < bestExtra {
            bestExtra = extra
        }
    }
    recommendations.append((config.name, bestExtra))
}

print("\n" + String(repeating: "=", count: 55))
print("📊 推荐额外步数:")
for (name, extra) in recommendations {
    print("   \(name): +\(extra) 步")
}
print("")
print("结论: 谎言模式应根据难度给不同的额外步数")
