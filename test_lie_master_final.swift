#!/usr/bin/env swift

// 最终验证：谎言模式大师级 (15步=10基础+5额外) 是否100%可解
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

func filterLieAware(_ candidates: [[PegColor]], history: [(guess: [PegColor], fb: Feedback)]) -> [[PegColor]] {
    return candidates.filter { cand in
        var mismatches = 0
        for h in history {
            if evaluate(guess: h.guess, secret: cand) != h.fb { mismatches += 1 }
            if mismatches > 1 { break }
        }
        return mismatches <= 1
    }
}

func optimalGuess(candidates: [[PegColor]], codeLen: Int) -> [PegColor] {
    if candidates.count <= 2 { return candidates[0] }
    let options = Array(candidates.prefix(min(80, candidates.count)))
    var best = options[0]; var bestWorst = candidates.count
    for g in options {
        var buckets: [Feedback: Int] = [:]
        for c in candidates { buckets[evaluate(guess: g, secret: c), default: 0] += 1 }
        let worst = buckets.values.max() ?? 0
        if worst < bestWorst || (worst == bestWorst && candidates.contains(where: { $0 == g })) {
            bestWorst = worst; best = g
        }
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

func solve(secret: [PegColor], allCandidates: [[PegColor]], maxAttempts: Int, lieAt: Int) -> Int? {
    let codeLen = secret.count
    var history: [(guess: [PegColor], fb: Feedback)] = []
    var candidates = allCandidates

    for attempt in 1...maxAttempts {
        if candidates.isEmpty { return nil }
        let guess = optimalGuess(candidates: candidates, codeLen: codeLen)
        let realFb = evaluate(guess: guess, secret: secret)

        let fb: Feedback
        if attempt == lieAt && !realFb.isWin(codeLen) {
            fb = makeLie(real: realFb, codeLen: codeLen)
        } else {
            fb = realFb
        }
        if fb.isWin(codeLen) { return attempt }

        history.append((guess, fb))
        candidates = filterLieAware(candidates, history: history)
    }
    return nil
}

// ============ 运行 ============

let maxAttempts = 15  // 大师谎言: 10基础 + 5额外
let codeLen = 6
let colorCount = 8
let sampleSize = 50

print("🧠 大师级谎言模式最终验证")
print("   配置: \(codeLen)位 \(colorCount)色 允许重复 \(maxAttempts)步")
print(String(repeating: "=", count: 55))

let allCodes = generateAll(codeLen: codeLen, colorCount: colorCount)
print("   候选总数: \(allCodes.count)")
print("   抽样数量: \(sampleSize)")
print("   谎言位置: 随机")
print("")

let secrets = Array(allCodes.shuffled().prefix(sampleSize))
var solved = 0; var failed = 0; var maxSteps = 0; var totalSteps = 0
var stepDistribution: [Int: Int] = [:]

let startTime = Date()

for (i, secret) in secrets.enumerated() {
    let lieAt = Int.random(in: 1...max(1, maxAttempts - 2))

    if let steps = solve(secret: secret, allCandidates: allCodes, maxAttempts: maxAttempts, lieAt: lieAt) {
        solved += 1
        maxSteps = max(maxSteps, steps)
        totalSteps += steps
        stepDistribution[steps, default: 0] += 1
    } else {
        failed += 1
        let codeStr = secret.map { "\($0.rawValue)" }.joined(separator: ",")
        print("   ❌ 失败 #\(i+1): 密码[\(codeStr)] 谎言在第\(lieAt)步")
    }

    if (i + 1) % 10 == 0 {
        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(solved) / Double(i + 1) * 100
        print("   进度: \(i+1)/\(sampleSize) | 成功率\(String(format:"%.0f",rate))% | 已用\(String(format:"%.0f",elapsed))s")
    }
}

let elapsed = Date().timeIntervalSince(startTime)

print("")
print(String(repeating: "=", count: 55))
print("📊 结果:")
print("   成功: \(solved)/\(sampleSize) (\(String(format:"%.1f", Double(solved)/Double(sampleSize)*100))%)")
print("   失败: \(failed)/\(sampleSize)")
print("   最难步数: \(maxSteps)/\(maxAttempts)")
print("   平均步数: \(String(format:"%.2f", Double(totalSteps)/Double(max(1,solved))))")
print("   余量: \(maxAttempts - maxSteps) 步")
print("   耗时: \(String(format:"%.1f", elapsed))秒")

print("")
print("📊 步数分布:")
for step in (stepDistribution.keys.sorted()) {
    let count = stepDistribution[step]!
    let bar = String(repeating: "█", count: count)
    print("   \(String(format:"%2d", step))步: \(bar) (\(count))")
}

print("")
if failed == 0 {
    print("🎉 大师级谎言模式 \(maxAttempts) 步内 100% 可解！余量 \(maxAttempts - maxSteps) 步。")
} else {
    print("⚠️  存在 \(failed) 个不可解情况。需要增加步数或优化求解策略。")
}
