import Foundation

enum PegColor: Int, CaseIterable, Codable, Identifiable {
    case red, green, blue, yellow, purple, orange, cyan, pink

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .red: return "红"
        case .green: return "绿"
        case .blue: return "蓝"
        case .yellow: return "黄"
        case .purple: return "紫"
        case .orange: return "橙"
        case .cyan: return "青"
        case .pink: return "粉"
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

struct GuessRecord: Identifiable {
    let id = UUID()
    let guess: [PegColor]
    let feedback: Feedback
}

enum GameMode: Equatable {
    case campaign(level: Int)
    case freePlay
    case duel
}

enum Difficulty: String, CaseIterable {
    case beginner = "新手"
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    case expert = "专家"
    case master = "大师"

    var codeLength: Int {
        switch self {
        case .beginner: return 3
        case .easy, .medium: return 4
        case .hard, .expert: return 5
        case .master: return 6
        }
    }

    var colorCount: Int {
        switch self {
        case .beginner: return 4
        case .easy: return 6
        case .medium: return 6
        case .hard: return 7
        case .expert: return 8
        case .master: return 8
        }
    }

    var maxAttempts: Int {
        switch self {
        case .beginner: return 10
        case .easy: return 8
        case .medium: return 7
        case .hard: return 8
        case .expert: return 9
        case .master: return 10
        }
    }

    var allowDuplicates: Bool {
        switch self {
        case .beginner, .easy: return false
        default: return true
        }
    }

    var hasTimeLimit: Bool {
        switch self {
        case .expert, .master: return true
        default: return false
        }
    }

    var timeLimitSeconds: Int {
        switch self {
        case .expert: return 120
        case .master: return 90
        default: return 0
        }
    }
}

struct Level: Identifiable, Codable {
    let id: Int
    let difficultyRaw: String
    let codeLength: Int
    let colorCount: Int
    let maxAttempts: Int
    let allowDuplicates: Bool
    let timeLimitSeconds: Int

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .easy
    }

    var tier: Int { (id - 1) / 20 + 1 }

    var tierName: String {
        switch tier {
        case 1: return "初级特工"
        case 2: return "中级特工"
        case 3: return "高级特工"
        case 4: return "精英特工"
        case 5: return "首席特工"
        default: return "传奇特工"
        }
    }
}

class GameEngine {
    let secretCode: [PegColor]
    let codeLength: Int
    let availableColors: [PegColor]
    let maxAttempts: Int
    let lieMode: Bool
    private(set) var lieUsed: Bool = false
    private(set) var lieAtGuess: Int? = nil
    private var guessCount: Int = 0
    private let lieAttemptNumber: Int?

    init(codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, lieMode: Bool = false) {
        self.codeLength = codeLength
        self.maxAttempts = maxAttempts
        self.lieMode = lieMode
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))

        if lieMode {
            // 谎言分配在普通模式最优求解步数内，保证一定会被遇到
            let optimalSteps: Int
            switch codeLength {
            case 3: optimalSteps = 4
            case 4: optimalSteps = 6
            case 5: optimalSteps = 8
            default: optimalSteps = 8
            }
            self.lieAttemptNumber = Int.random(in: 1...max(1, optimalSteps - 1))
        } else {
            self.lieAttemptNumber = nil
        }

        if allowDuplicates {
            self.secretCode = (0..<codeLength).map { _ in
                PegColor.allCases[Int.random(in: 0..<colorCount)]
            }
        } else {
            var pool = Array(PegColor.allCases.prefix(colorCount))
            var code: [PegColor] = []
            for _ in 0..<codeLength {
                let idx = Int.random(in: 0..<pool.count)
                code.append(pool.remove(at: idx))
            }
            self.secretCode = code
        }
    }

    init(secretCode: [PegColor], colorCount: Int, maxAttempts: Int) {
        self.secretCode = secretCode
        self.codeLength = secretCode.count
        self.availableColors = Array(PegColor.allCases.prefix(colorCount))
        self.maxAttempts = maxAttempts
        self.lieMode = false
        self.lieAttemptNumber = nil
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
        // 选一个"接近真实值"的谎言，让它更难识破
        let close = options.filter {
            abs($0.exact - real.exact) <= 1 && abs($0.partial - real.partial) <= 1
        }
        return (close.isEmpty ? options : close).randomElement()
            ?? Feedback(exact: max(0, real.exact - 1), partial: real.partial, isLie: true)
    }
}

class LevelManager {
    static let shared = LevelManager()

    let levels: [Level]

    private init() {
        var generated: [Level] = []
        let configs: [(Difficulty, Int)] = [
            (.beginner, 20), (.easy, 20), (.medium, 20),
            (.hard, 20), (.expert, 20), (.master, 20),
        ]
        var id = 1
        for (diff, count) in configs {
            for j in 0..<count {
                let progress = Double(j) / Double(count)
                var attempts = diff.maxAttempts
                if progress > 0.5 { attempts = max(attempts - 1, diff.codeLength + 1) }
                if progress > 0.8 { attempts = max(attempts - 1, diff.codeLength + 1) }

                let timeLimit: Int
                if diff.hasTimeLimit {
                    let base = diff.timeLimitSeconds
                    timeLimit = max(30, base - Int(progress * 40))
                } else {
                    timeLimit = 0
                }

                generated.append(Level(
                    id: id,
                    difficultyRaw: diff.rawValue,
                    codeLength: diff.codeLength,
                    colorCount: diff.colorCount,
                    maxAttempts: attempts,
                    allowDuplicates: diff.allowDuplicates,
                    timeLimitSeconds: timeLimit
                ))
                id += 1
            }
        }
        self.levels = generated
    }

    func level(for id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    var tiers: [[Level]] {
        Dictionary(grouping: levels) { $0.tier }
            .sorted { $0.key < $1.key }
            .map { $0.value }
    }
}

class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    static let lieShared = ProgressManager(prefix: "lie_")

    @Published var completedLevels: Set<Int> {
        didSet { save() }
    }
    @Published var starsByLevel: [Int: Int] {
        didSet { save() }
    }

    private let completedKey: String
    private let starsKey: String

    init(prefix: String = "") {
        completedKey = "\(prefix)completedLevels"
        starsKey = "\(prefix)starsByLevel"

        let savedCompleted = UserDefaults.standard.array(forKey: completedKey) as? [Int] ?? []
        self.completedLevels = Set(savedCompleted)

        let savedStars = UserDefaults.standard.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        var stars: [Int: Int] = [:]
        for (k, v) in savedStars { if let i = Int(k) { stars[i] = v } }
        self.starsByLevel = stars
    }

    private func save() {
        UserDefaults.standard.set(Array(completedLevels), forKey: completedKey)
        let stringKeyed = Dictionary(uniqueKeysWithValues: starsByLevel.map { (String($0.key), $0.value) })
        UserDefaults.standard.set(stringKeyed, forKey: starsKey)
    }

    func complete(level: Int, attempts: Int, maxAttempts: Int) {
        completedLevels.insert(level)
        let ratio = Double(attempts) / Double(maxAttempts)
        let stars: Int
        if ratio <= 0.3 { stars = 3 }
        else if ratio <= 0.6 { stars = 2 }
        else { stars = 1 }
        if stars > (starsByLevel[level] ?? 0) {
            starsByLevel[level] = stars
        }
    }

    func isUnlocked(level: Int) -> Bool {
        #if DEBUG
        return true
        #else
        return level == 1 || completedLevels.contains(level - 1)
        #endif
    }

    var totalStars: Int {
        starsByLevel.values.reduce(0, +)
    }
}

class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published var gamesPlayed: Int {
        didSet { UserDefaults.standard.set(gamesPlayed, forKey: "stats_gamesPlayed") }
    }
    @Published var gamesWon: Int {
        didSet { UserDefaults.standard.set(gamesWon, forKey: "stats_gamesWon") }
    }
    @Published var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "stats_currentStreak") }
    }
    @Published var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: "stats_bestStreak") }
    }
    @Published var totalAttempts: Int {
        didSet { UserDefaults.standard.set(totalAttempts, forKey: "stats_totalAttempts") }
    }

    var winRate: Double {
        gamesPlayed == 0 ? 0 : Double(gamesWon) / Double(gamesPlayed) * 100
    }

    var avgAttempts: Double {
        gamesWon == 0 ? 0 : Double(totalAttempts) / Double(gamesWon)
    }

    private init() {
        gamesPlayed = UserDefaults.standard.integer(forKey: "stats_gamesPlayed")
        gamesWon = UserDefaults.standard.integer(forKey: "stats_gamesWon")
        currentStreak = UserDefaults.standard.integer(forKey: "stats_currentStreak")
        bestStreak = UserDefaults.standard.integer(forKey: "stats_bestStreak")
        totalAttempts = UserDefaults.standard.integer(forKey: "stats_totalAttempts")
    }

    func recordWin(attempts: Int) {
        gamesPlayed += 1
        gamesWon += 1
        totalAttempts += attempts
        currentStreak += 1
        if currentStreak > bestStreak { bestStreak = currentStreak }
    }

    func recordLoss() {
        gamesPlayed += 1
        currentStreak = 0
    }
}
