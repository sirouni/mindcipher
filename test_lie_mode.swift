#!/usr/bin/env swift

// 谎言模式测试脚本
import Foundation

enum PegColor: Int, CaseIterable { case red, green, blue, yellow, purple, orange, cyan, pink }

struct Feedback: Equatable {
    let exact: Int; let partial: Int; let isLie: Bool
    init(exact: Int, partial: Int, isLie: Bool = false) {
        self.exact = exact; self.partial = partial; self.isLie = isLie
    }
    func isWin(_ len: Int) -> Bool { exact == len && !isLie }
}

class GameEngine {
    let secretCode: [PegColor]
    let codeLength: Int
    let availableColors: [PegColor]
    let maxAttempts: Int
    let lieMode: Bool
    private(set) var lieUsed = false
    private(set) var lieAtGuess: Int? = nil
    private var guessCount = 0
    private let lieAttemptNumber: Int?

    init(codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false) {
        self.codeLength = codeLength
        self.maxAttempts = maxAttempts
        self.lieMode = lieMode
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))
        self.lieAttemptNumber = lieMode ? Int.random(in: 1...max(1, maxAttempts - 2)) : nil

        if allowDuplicates {
            self.secretCode = (0..<codeLength).map { _ in PegColor.allCases[Int.random(in: 0..<colorCount)] }
        } else {
            var pool = Array(PegColor.allCases.prefix(colorCount))
            var code: [PegColor] = []
            for _ in 0..<codeLength { let i = Int.random(in: 0..<pool.count); code.append(pool.remove(at: i)) }
            self.secretCode = code
        }
    }

    func evaluate(guess: [PegColor]) -> Feedback {
        guard guess.count == codeLength else { return Feedback(exact: 0, partial: 0) }
        guessCount += 1
        let real = computeReal(guess: guess)
        if lieMode && !lieUsed && guessCount == lieAttemptNumber && !real.isWin(codeLength) {
            lieUsed = true
            lieAtGuess = guessCount
            return generateLie(real: real)
        }
        return real
    }

    func computeReal(guess: [PegColor]) -> Feedback {
        var exact = 0; var sR: [PegColor] = []; var gR: [PegColor] = []
        for i in 0..<codeLength {
            if guess[i] == secretCode[i] { exact += 1 }
            else { sR.append(secretCode[i]); gR.append(guess[i]) }
        }
        var partial = 0; var pool = sR
        for c in gR { if let i = pool.firstIndex(of: c) { partial += 1; pool.remove(at: i) } }
        return Feedback(exact: exact, partial: partial)
    }

    private func generateLie(real: Feedback) -> Feedback {
        var options: [Feedback] = []
        for e in 0...codeLength {
            for p in 0...(codeLength - e) {
                let f = Feedback(exact: e, partial: p, isLie: true)
                if f.exact != real.exact || f.partial != real.partial { options.append(f) }
            }
        }
        let close = options.filter { abs($0.exact - real.exact) <= 1 && abs($0.partial - real.partial) <= 1 }
        return (close.isEmpty ? options : close).randomElement()
            ?? Feedback(exact: max(0, real.exact - 1), partial: real.partial, isLie: true)
    }
}

// ============ 测试 ============

var tests = 0; var pass = 0

func assert(_ condition: Bool, _ msg: String) {
    tests += 1
    if condition { pass += 1 }
    else { print("  ❌ FAIL: \(msg)") }
}

print("🎭 谎言模式测试")
print(String(repeating: "=", count: 50))

// 测试1: 非谎言模式不会产生谎言
print("\n📋 测试1: lieMode=false 不产生谎言")
for _ in 0..<20 {
    let engine = GameEngine(codeLength: 4, colorCount: 6, allowDuplicates: false, maxAttempts: 8, lieMode: false)
    for _ in 0..<8 {
        let guess = (0..<4).map { _ in PegColor.allCases[Int.random(in: 0..<6)] }
        let fb = engine.evaluate(guess: guess)
        assert(!fb.isLie, "非谎言模式产生了谎言")
    }
    assert(!engine.lieUsed, "非谎言模式 lieUsed 应为 false")
}
print("  ✅ \(pass)/\(tests)")

// 测试2: 谎言模式恰好产生1次谎言
print("\n📋 测试2: lieMode=true 恰好产生1次谎言")
let t2Start = tests
var lieCount = 0
for _ in 0..<100 {
    let engine = GameEngine(codeLength: 4, colorCount: 6, allowDuplicates: false, maxAttempts: 8, lieMode: true)
    var lies = 0
    for _ in 0..<8 {
        let guess = (0..<4).map { _ in PegColor.allCases[Int.random(in: 0..<6)] }
        let fb = engine.evaluate(guess: guess)
        if fb.isLie { lies += 1 }
    }
    assert(lies <= 1, "产生了 \(lies) 次谎言，应最多1次")
    if lies == 1 { lieCount += 1 }
}
print("  ✅ \(pass - t2Start + (tests - t2Start == pass - t2Start ? 0 : 0))/100 局最多1次谎言")
print("  📊 \(lieCount)/100 局实际产生了谎言")

// 测试3: 谎言反馈与真实反馈不同
print("\n📋 测试3: 谎言反馈 ≠ 真实反馈")
let t3Start = tests
for _ in 0..<100 {
    let engine = GameEngine(codeLength: 4, colorCount: 6, allowDuplicates: false, maxAttempts: 8, lieMode: true)
    for _ in 0..<8 {
        let guess = (0..<4).map { _ in PegColor.allCases[Int.random(in: 0..<6)] }
        let fb = engine.evaluate(guess: guess)
        if fb.isLie {
            let real = engine.computeReal(guess: guess)
            assert(fb.exact != real.exact || fb.partial != real.partial,
                   "谎言反馈(\(fb.exact),\(fb.partial))与真实反馈(\(real.exact),\(real.partial))相同")
        }
    }
}
print("  ✅ 谎言内容验证通过")

// 测试4: 谎言接近真实值（差距≤1）
print("\n📋 测试4: 谎言与真实值差距 ≤1")
let t4Start = tests
var closeCount = 0
var totalLies = 0
for _ in 0..<200 {
    let engine = GameEngine(codeLength: 4, colorCount: 6, allowDuplicates: false, maxAttempts: 8, lieMode: true)
    for _ in 0..<8 {
        let guess = (0..<4).map { _ in PegColor.allCases[Int.random(in: 0..<6)] }
        let fb = engine.evaluate(guess: guess)
        if fb.isLie {
            let real = engine.computeReal(guess: guess)
            totalLies += 1
            if abs(fb.exact - real.exact) <= 1 && abs(fb.partial - real.partial) <= 1 {
                closeCount += 1
            }
        }
    }
}
let closeRate = totalLies > 0 ? Double(closeCount) / Double(totalLies) * 100 : 0
print("  📊 谎言接近真实值比例: \(closeCount)/\(totalLies) (\(String(format: "%.0f", closeRate))%)")
assert(closeRate > 80, "接近率应 >80%，实际 \(closeRate)%")

// 测试5: 不会在猜对时撒谎
print("\n📋 测试5: 猜对时不撒谎")
let t5Start = tests
for _ in 0..<50 {
    let engine = GameEngine(codeLength: 3, colorCount: 4, allowDuplicates: false, maxAttempts: 10, lieMode: true)
    let fb = engine.evaluate(guess: engine.secretCode) // 直接猜对
    assert(!fb.isLie, "猜对时不应撒谎")
    assert(fb.isWin(3), "猜对应判胜")
}
print("  ✅ 猜对时永不撒谎")

// 测试6: 谎言出现位置在 [1, maxAttempts-2] 范围内
print("\n📋 测试6: 谎言出现时机合理")
var liePositions: [Int] = []
for _ in 0..<200 {
    let engine = GameEngine(codeLength: 4, colorCount: 6, allowDuplicates: false, maxAttempts: 8, lieMode: true)
    for _ in 0..<8 {
        let guess = (0..<4).map { _ in PegColor.allCases[Int.random(in: 0..<6)] }
        let _ = engine.evaluate(guess: guess)
    }
    if let pos = engine.lieAtGuess { liePositions.append(pos) }
}
let minPos = liePositions.min() ?? 0
let maxPos = liePositions.max() ?? 0
print("  📊 谎言出现范围: 第\(minPos)步 ~ 第\(maxPos)步 (应在1~6)")
assert(minPos >= 1, "谎言不应在第0步")
assert(maxPos <= 6, "谎言不应在最后2步 (maxAttempts=8)")

// 测试7: isWin 在谎言时返回 false
print("\n📋 测试7: isWin 在谎言时返回 false")
let lieWin = Feedback(exact: 4, partial: 0, isLie: true)
assert(!lieWin.isWin(4), "谎言 exact==codeLength 不应判胜")
let realWin = Feedback(exact: 4, partial: 0, isLie: false)
assert(realWin.isWin(4), "真实 exact==codeLength 应判胜")
print("  ✅ isWin 逻辑正确")

// ============ 汇总 ============
print("\n" + String(repeating: "=", count: 50))
print("📊 测试汇总: \(pass)/\(tests) 通过")
if pass == tests {
    print("🎉 谎言模式全部测试通过！")
} else {
    print("⚠️  有 \(tests - pass) 个测试失败")
}
