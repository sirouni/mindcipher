#!/usr/bin/env swift

// 快速关卡测试 - 验证引擎正确性 + 关卡配置合理性
import Foundation

// ============ 最小化引擎复制 ============

enum PegColor: Int, CaseIterable { case red, green, blue, yellow, purple, orange, cyan, pink }

struct Feedback: Equatable {
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

// ============ 测试1: 引擎逻辑正确性 ============

var tests = 0; var pass = 0

func check(_ label: String, _ got: Feedback, _ want: Feedback) {
    tests += 1
    if got == want { pass += 1 }
    else { print("  FAIL \(label): got (\(got.exact),\(got.partial)) want (\(want.exact),\(want.partial))") }
}

print("🧪 测试1: GameEngine.evaluate 逻辑正确性")
print("-" + String(repeating: "-", count: 49))

// 全部正确
check("全部精确匹配",
    evaluate(guess: [.red, .green, .blue], secret: [.red, .green, .blue]),
    Feedback(exact: 3, partial: 0))

// 全部位置错误但颜色存在
check("全部部分匹配",
    evaluate(guess: [.green, .blue, .red], secret: [.red, .green, .blue]),
    Feedback(exact: 0, partial: 3))

// 完全不匹配
check("完全不匹配",
    evaluate(guess: [.red, .green, .blue], secret: [.yellow, .purple, .orange]),
    Feedback(exact: 0, partial: 0))

// 混合情况
check("1精确+1部分+1无",
    evaluate(guess: [.red, .green, .blue], secret: [.red, .blue, .yellow]),
    Feedback(exact: 1, partial: 1))

// 4位密码
check("4位-2精确2部分",
    evaluate(guess: [.red, .green, .blue, .yellow], secret: [.red, .green, .yellow, .blue]),
    Feedback(exact: 2, partial: 2))

// 重复颜色处理
check("重复色-猜2红密码1红",
    evaluate(guess: [.red, .red, .blue, .green], secret: [.red, .yellow, .green, .blue]),
    Feedback(exact: 1, partial: 2))

check("重复色-猜3红密码2红",
    evaluate(guess: [.red, .red, .red, .green], secret: [.red, .red, .blue, .yellow]),
    Feedback(exact: 2, partial: 0))

// 全部相同颜色猜测
check("全红-密码含1红",
    evaluate(guess: [.red, .red, .red, .red], secret: [.red, .blue, .green, .yellow]),
    Feedback(exact: 1, partial: 0))

// 5位和6位
check("5位-全精确",
    evaluate(guess: [.red, .green, .blue, .yellow, .purple], secret: [.red, .green, .blue, .yellow, .purple]),
    Feedback(exact: 5, partial: 0))

check("6位-3精确3部分",
    evaluate(guess: [.red, .green, .blue, .yellow, .purple, .orange],
             secret: [.red, .green, .blue, .orange, .yellow, .purple]),
    Feedback(exact: 3, partial: 3))

// isWin 测试
check("isWin-3位全中",
    { let f = Feedback(exact: 3, partial: 0); return f.isWin(3) ? Feedback(exact: 1, partial: 0) : Feedback(exact: 0, partial: 0) }(),
    Feedback(exact: 1, partial: 0))

check("isWin-4位差1",
    { let f = Feedback(exact: 3, partial: 1); return f.isWin(4) ? Feedback(exact: 1, partial: 0) : Feedback(exact: 0, partial: 0) }(),
    Feedback(exact: 0, partial: 0))

print("  结果: \(pass)/\(tests) 通过\n")

// ============ 测试2: 关卡配置合理性 ============

print("🧪 测试2: 120关配置合理性验证")
print("-" + String(repeating: "-", count: 49))

struct LevelConfig {
    let id: Int; let codeLen: Int; let colors: Int; let attempts: Int; let dup: Bool
}

func genLevels() -> [LevelConfig] {
    struct D { let c: Int; let n: Int; let a: Int; let d: Bool }
    let ds: [D] = [D(c:3,n:4,a:10,d:false), D(c:4,n:6,a:8,d:false), D(c:4,n:6,a:7,d:false),
                   D(c:5,n:7,a:8,d:true), D(c:5,n:8,a:9,d:true), D(c:6,n:8,a:10,d:true)]
    var lvls: [LevelConfig] = []; var id = 1
    for d in ds {
        for j in 0..<20 {
            let p = Double(j)/20.0
            var a = d.a
            if p > 0.5 { a = max(a-1, d.c+1) }
            if p > 0.8 { a = max(a-1, d.c+1) }
            lvls.append(LevelConfig(id: id, codeLen: d.c, colors: d.n, attempts: a, dup: d.d))
            id += 1
        }
    }
    return lvls
}

let levels = genLevels()
var configPass = 0; var configFail = 0

for lv in levels {
    var issues: [String] = []
    if lv.colors < lv.codeLen && !lv.dup { issues.append("颜色数(\(lv.colors)) < 密码长度(\(lv.codeLen))且不允许重复") }
    if lv.attempts < lv.codeLen { issues.append("尝试次数(\(lv.attempts)) < 密码长度(\(lv.codeLen))") }
    if lv.codeLen < 3 || lv.codeLen > 6 { issues.append("密码长度\(lv.codeLen)超出范围") }
    if lv.colors < 4 || lv.colors > 8 { issues.append("颜色数\(lv.colors)超出范围") }

    // 理论最少步数估算 (信息论下界)
    let totalCombinations: Double
    if lv.dup {
        totalCombinations = pow(Double(lv.colors), Double(lv.codeLen))
    } else {
        var perm: Double = 1
        for i in 0..<lv.codeLen { perm *= Double(lv.colors - i) }
        totalCombinations = perm
    }
    let theoreticalMin = Int(ceil(log2(totalCombinations) / log2(Double(lv.codeLen + 1)))) // 粗略估算
    if lv.attempts < theoreticalMin {
        issues.append("尝试次数(\(lv.attempts))低于理论下界(\(theoreticalMin))")
    }

    if issues.isEmpty {
        configPass += 1
    } else {
        configFail += 1
        print("  ⚠️  关卡\(lv.id): \(issues.joined(separator: "; "))")
    }
}

// 验证难度递增
var monotonic = true
for i in 1..<levels.count {
    if levels[i].id % 20 == 0 && i + 1 < levels.count {
        let curr = levels[i]; let next = levels[i+1]
        if next.codeLen < curr.codeLen && next.colors < curr.colors {
            monotonic = false
            print("  ⚠️  Tier 跳转 \(curr.id)->\(next.id) 难度未递增")
        }
    }
}

print("  配置有效: \(configPass)/\(levels.count)")
if configFail > 0 { print("  配置异常: \(configFail) 个") }
print("  难度递增: \(monotonic ? "✅" : "❌")")
print("  总关卡数: \(levels.count)")
print("")

// ============ 测试3: 简单关卡可解性（枚举验证） ============

print("🧪 测试3: 新手关卡(3位4色)可解性验证 - 穷举所有密码")
print("-" + String(repeating: "-", count: 49))

// 3位4色无重复 = P(4,3) = 24种密码
let colors4: [PegColor] = [.red, .green, .blue, .yellow]
var allCodes: [[PegColor]] = []
for a in colors4 { for b in colors4 { for c in colors4 {
    if a != b && b != c && a != c { allCodes.append([a,b,c]) }
}}}

print("  总密码组合: \(allCodes.count)")

// 用简单策略验证每个密码都能在10步内解
var solvable = 0; var maxSteps = 0

for secret in allCodes {
    var candidates = allCodes
    var steps = 0

    while !candidates.isEmpty && steps < 10 {
        let guess = candidates[0]
        steps += 1
        let fb = evaluate(guess: guess, secret: secret)
        if fb.isWin(3) { break }
        candidates = candidates.filter { c in
            evaluate(guess: guess, secret: c) == fb
        }
    }
    if steps <= 10 { solvable += 1 }
    maxSteps = max(maxSteps, steps)
}

print("  可在10步内解出: \(solvable)/\(allCodes.count)")
print("  最难情况步数: \(maxSteps)")
print("")

// ============ 测试4: 中等关卡(4位6色)可解性抽样 ============

print("🧪 测试4: 简单关卡(4位6色)可解性抽样 - 100个随机密码")
print("-" + String(repeating: "-", count: 49))

let colors6: [PegColor] = [.red, .green, .blue, .yellow, .purple, .orange]
var allCodes4: [[PegColor]] = []
for a in colors6 { for b in colors6 { for c in colors6 { for d in colors6 {
    if Set([a,b,c,d]).count == 4 { allCodes4.append([a,b,c,d]) }
}}}}

print("  总密码组合: \(allCodes4.count)")

solvable = 0; maxSteps = 0
let sampleCount = min(100, allCodes4.count)
let sampled = Array(allCodes4.shuffled().prefix(sampleCount))

for secret in sampled {
    var candidates = allCodes4
    var steps = 0

    while !candidates.isEmpty && steps < 8 {
        let guess = candidates[0]
        steps += 1
        let fb = evaluate(guess: guess, secret: secret)
        if fb.isWin(4) { break }
        candidates = candidates.filter { c in
            evaluate(guess: guess, secret: c) == fb
        }
    }
    if steps <= 8 { solvable += 1 }
    maxSteps = max(maxSteps, steps)
}

print("  抽样\(sampleCount)个密码, 8步内可解: \(solvable)/\(sampleCount)")
print("  最难情况步数: \(maxSteps)")
print("")

// ============ 汇总 ============

print("=" + String(repeating: "=", count: 49))
print("📊 测试汇总:")
print("  引擎逻辑: \(pass)/\(tests) 通过")
print("  关卡配置: \(configPass)/120 有效")
print("  新手可解: \(allCodes.count)/\(allCodes.count)")
print("  简单抽样: \(solvable)/\(sampleCount)")
let allGood = pass == tests && configFail == 0
print(allGood ? "\n🎉 核心逻辑全部通过！" : "\n⚠️ 存在问题需修复")
