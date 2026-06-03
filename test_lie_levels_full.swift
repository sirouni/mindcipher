#!/usr/bin/env swift

// 谎言关卡模式全量通关测试
// 验证120关谎言任务是否全部可在限定步数内通关
import Foundation

enum PegColor: Int, CaseIterable { case red, green, blue, yellow, purple, orange, cyan, pink }

struct Feedback: Hashable {
    let exact: Int; let partial: Int
    func isWin(_ len: Int) -> Bool { exact == len }
}

func evaluate(guess: [PegColor], secret: [PegColor]) -> Feedback {
    let n = secret.count
    var exact = 0; var sR = [PegColor](); var gR = [PegColor]()
    for i in 0..<n {
        if guess[i] == secret[i] { exact += 1 } else { sR.append(secret[i]); gR.append(guess[i]) }
    }
    var partial = 0; var pool = sR
    for c in gR { if let i = pool.firstIndex(of: c) { partial += 1; pool.remove(at: i) } }
    return Feedback(exact: exact, partial: partial)
}

func generateAll(codeLen: Int, colorCount: Int, allowDup: Bool) -> [[PegColor]] {
    let colors = Array(PegColor.allCases.prefix(colorCount))
    var results = [[PegColor]]()
    if allowDup {
        func gen(_ c: [PegColor]) { if c.count == codeLen { results.append(c); return }; for co in colors { gen(c+[co]) } }
        gen([])
    } else {
        func gen(_ c: [PegColor], _ r: [PegColor]) {
            if c.count == codeLen { results.append(c); return }
            for (i,co) in r.enumerated() { var rr=r; rr.remove(at:i); gen(c+[co], rr) }
        }
        gen([], colors)
    }
    return results
}

func optimalGuess(candidates: [[PegColor]], codeLen: Int) -> [PegColor] {
    if candidates.count <= 2 { return candidates[0] }
    let opts = Array(candidates.prefix(min(60, candidates.count)))
    var best = opts[0]; var bestW = candidates.count
    for g in opts {
        var bk = [Feedback:Int](); for c in candidates { bk[evaluate(guess:g,secret:c), default:0] += 1 }
        let w = bk.values.max() ?? 0
        if w < bestW { bestW = w; best = g }
    }
    return best
}

func makeLie(real: Feedback, codeLen: Int) -> Feedback {
    for (de,dp) in [(-1,0),(1,0),(0,-1),(0,1),(-1,1),(1,-1)].shuffled() {
        let e = real.exact+de, p = real.partial+dp
        if e >= 0 && p >= 0 && e+p <= codeLen && (e != real.exact || p != real.partial) {
            return Feedback(exact: e, partial: p)
        }
    }
    return Feedback(exact: max(0, real.exact-1), partial: real.partial)
}

func solve(secret: [PegColor], allCands: [[PegColor]], maxAtt: Int, lieAt: Int) -> Int? {
    let n = secret.count
    var hist = [([PegColor], Feedback)]()
    var cands = allCands
    for att in 1...maxAtt {
        if cands.isEmpty { return nil }
        let guess = optimalGuess(candidates: cands, codeLen: n)
        let real = evaluate(guess: guess, secret: secret)
        let fb: Feedback
        if att == lieAt && !real.isWin(n) { fb = makeLie(real: real, codeLen: n) } else { fb = real }
        if fb.isWin(n) { return att }
        hist.append((guess, fb))
        cands = cands.filter { c in
            var miss = 0
            for (g,f) in hist { if evaluate(guess:g,secret:c) != f { miss += 1 }; if miss > 1 { return false } }
            return true
        }
    }
    return nil
}

// ============ 关卡配置（与 Models.swift 一致） ============

struct Level {
    let id: Int; let codeLen: Int; let colors: Int; let attempts: Int; let dup: Bool; let diff: String
}

func genLevels() -> [Level] {
    struct D { let n: String; let c: Int; let co: Int; let a: Int; let d: Bool }
    let ds = [D(n:"新手",c:3,co:4,a:10,d:false), D(n:"简单",c:4,co:6,a:8,d:false),
              D(n:"中等",c:4,co:6,a:7,d:false), D(n:"困难",c:5,co:7,a:8,d:true),
              D(n:"专家",c:5,co:8,a:9,d:true), D(n:"大师",c:6,co:8,a:10,d:true)]
    var lvls = [Level](); var id = 1
    for d in ds {
        for j in 0..<20 {
            let p = Double(j)/20.0
            var a = d.a
            if p > 0.5 { a = max(a-1, d.c+1) }
            if p > 0.8 { a = max(a-1, d.c+1) }
            // 谎言额外步数
            let extra: Int
            switch d.n {
            case "新手": extra = 5
            case "简单": extra = 7
            case "中等": extra = 8
            case "困难": extra = 7
            case "专家": extra = 7
            case "大师": extra = 5
            default: extra = 5
            }
            lvls.append(Level(id:id, codeLen:d.c, colors:d.co, attempts:a+extra, dup:d.d, diff:d.n))
            id += 1
        }
    }
    return lvls
}

// ============ 运行测试 ============

print("🎭 谎言关卡模式 — 120关全量通关测试")
print(String(repeating: "=", count: 55))

let levels = genLevels()
var passed = 0; var failed = 0; var maxByTier = [String: Int]()
// 新手~中等: 3次, 困难~专家: 2次, 大师: 1次
func trialsFor(_ diff: String) -> Int {
    switch diff {
    case "新手","简单","中等": return 3
    case "困难","专家": return 2
    case "大师": return 1
    default: return 1
    }
}
let trialsPerLevel = 0 // unused, use trialsFor()

let startTime = Date()

for level in levels {
    let allCands = generateAll(codeLen: level.codeLen, colorCount: level.colors, allowDup: level.dup)
    var levelOK = true
    var worstSteps = 0

    for trial in 0..<trialsFor(level.diff) {
        let secret = allCands.randomElement()!
        let lieAt = Int.random(in: 1...max(1, level.attempts - 2))
        if let steps = solve(secret: secret, allCands: allCands, maxAtt: level.attempts, lieAt: lieAt) {
            worstSteps = max(worstSteps, steps)
        } else {
            levelOK = false
            print("  ❌ 关卡\(level.id)(\(level.diff)) 试次\(trial+1) 失败! \(level.codeLen)位\(level.colors)色 \(level.attempts)步")
            break
        }
    }

    if levelOK {
        passed += 1
        maxByTier[level.diff, default: 0] = max(maxByTier[level.diff, default: 0], worstSteps)
    } else {
        failed += 1
    }

    if level.id % 20 == 0 {
        let elapsed = Date().timeIntervalSince(startTime)
        print("  [\(level.diff)] 关卡\(level.id-19)-\(level.id): \(failed == 0 ? "✅" : "⚠️") 最难\(maxByTier[level.diff] ?? 0)步 [\(String(format:"%.0f",elapsed))s]")
    }
}

let elapsed = Date().timeIntervalSince(startTime)

print("")
print(String(repeating: "=", count: 55))
print("📊 结果:")
print("  通过: \(passed)/\(levels.count)")
print("  失败: \(failed)/\(levels.count)")
print("  耗时: \(String(format:"%.1f",elapsed))秒")
print("")
print("📊 各难度最难步数:")
for diff in ["新手","简单","中等","困难","专家","大师"] {
    if let m = maxByTier[diff] {
        let lvl = levels.first { $0.diff == diff }!
        print("  \(diff): 最难\(m)/\(lvl.attempts)步")
    }
}

if failed == 0 {
    print("\n🎉 谎言关卡120关全部可通关！")
} else {
    print("\n⚠️ 有\(failed)关无法通关，需调整参数。")
}
