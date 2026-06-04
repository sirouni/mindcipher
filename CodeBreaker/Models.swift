import Foundation

enum PegColor: Int, CaseIterable, Codable, Identifiable {
    case red, green, blue, yellow, purple, orange, cyan, pink

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .cyan: return "Cyan"
        case .pink: return "Pink"
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
    case beginner = "Beginner"
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    case master = "Master"

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
        case .easy: return 9
        case .medium: return 9
        case .hard: return 10
        case .expert: return 12
        case .master: return 14
        }
    }

    var allowDuplicates: Bool {
        switch self {
        case .beginner, .easy: return false
        default: return true
        }
    }

    var hasTimeLimit: Bool { false }

    var timeLimitSeconds: Int { 0 }

    var lieExtraAttempts: Int {
        switch self {
        case .beginner: return 5
        case .easy: return 7
        case .medium: return 8
        case .hard: return 7
        case .expert: return 7
        case .master: return 5
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

    var tier: Int { (id - 1) / 40 + 1 }

    var tierName: String {
        switch tier {
        case 1: return "Junior Agent"
        case 2: return "Agent"
        case 3: return "Senior Agent"
        case 4: return "Elite Agent"
        case 5: return "Chief Agent"
        default: return "Legend Agent"
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
            (.beginner, 40), (.easy, 40), (.medium, 40),
            (.hard, 40), (.expert, 40), (.master, 40),
        ]
        let minAttempts: [Difficulty: Int] = [
            .beginner: 8, .easy: 8, .medium: 8,
            .hard: 9, .expert: 10, .master: 12,
        ]
        var id = 1
        for (diff, count) in configs {
            let floor = minAttempts[diff] ?? (diff.codeLength + 2)
            for j in 0..<count {
                let progress = Double(j) / Double(count)
                var attempts = diff.maxAttempts
                if progress > 0.5 { attempts -= 1 }
                if progress > 0.8 { attempts -= 1 }
                attempts = max(attempts, floor)

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
        level == 1 || completedLevels.contains(level - 1)
    }

    var totalStars: Int {
        starsByLevel.values.reduce(0, +)
    }
}

// MARK: - Achievements

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let desc: String
    let category: AchievementCategory
    let check: (StatsManager, ProgressManager, ProgressManager) -> Bool
}

enum AchievementCategory: String, CaseIterable {
    case beginner = "Getting Started"
    case streak = "Streaks"
    case daily = "Daily Challenge"
    case freeplay = "Free Play"
    case duel = "Duel Mode"
    case levels = "Levels"
    case stars = "Stars"
    case mastery = "Mastery"
    case speed = "Speed"
}

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var unlockedIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(unlockedIds), forKey: "achievements_unlocked") }
    }
    @Published var newlyUnlocked: Achievement?

    static let all: [Achievement] = [
        // Getting Started
        Achievement(id: "first_win", icon: "lock.open.fill", title: "First Crack", desc: "Win your first game", category: .beginner) { s,_,_ in s.gamesWon >= 1 },
        Achievement(id: "play_5", icon: "gamecontroller.fill", title: "Warming Up", desc: "Play 5 games", category: .beginner) { s,_,_ in s.gamesPlayed >= 5 },
        Achievement(id: "play_10", icon: "gamecontroller.fill", title: "Getting Hooked", desc: "Play 10 games", category: .beginner) { s,_,_ in s.gamesPlayed >= 10 },
        Achievement(id: "play_50", icon: "gamecontroller.fill", title: "Dedicated", desc: "Play 50 games", category: .beginner) { s,_,_ in s.gamesPlayed >= 50 },
        Achievement(id: "play_100", icon: "gamecontroller.fill", title: "Veteran", desc: "Play 100 games", category: .beginner) { s,_,_ in s.gamesPlayed >= 100 },
        Achievement(id: "win_10", icon: "trophy.fill", title: "Double Digits", desc: "Win 10 games", category: .beginner) { s,_,_ in s.gamesWon >= 10 },
        Achievement(id: "win_50", icon: "trophy.fill", title: "Half Century", desc: "Win 50 games", category: .beginner) { s,_,_ in s.gamesWon >= 50 },

        // Streaks
        Achievement(id: "streak_3", icon: "flame.fill", title: "On Fire", desc: "Win 3 in a row", category: .streak) { s,_,_ in s.bestStreak >= 3 },
        Achievement(id: "streak_5", icon: "flame.fill", title: "Streak Master", desc: "Win 5 in a row", category: .streak) { s,_,_ in s.bestStreak >= 5 },
        Achievement(id: "streak_10", icon: "scope", title: "Sharpshooter", desc: "Win 10 in a row", category: .streak) { s,_,_ in s.bestStreak >= 10 },
        Achievement(id: "streak_20", icon: "bolt.fill", title: "Unstoppable", desc: "Win 20 in a row", category: .streak) { s,_,_ in s.bestStreak >= 20 },
        Achievement(id: "winrate_80", icon: "percent", title: "Consistent", desc: "Maintain 80%+ win rate (10+ games)", category: .streak) { s,_,_ in s.gamesPlayed >= 10 && s.winRate >= 80 },

        // Daily Challenge
        Achievement(id: "daily_1", icon: "calendar", title: "Daily Debut", desc: "Complete your first daily challenge", category: .daily) { _,_,_ in AchievementManager.dailyWins >= 1 },
        Achievement(id: "daily_7", icon: "calendar.badge.clock", title: "Weekly Habit", desc: "Complete 7 daily challenges", category: .daily) { _,_,_ in AchievementManager.dailyWins >= 7 },
        Achievement(id: "daily_30", icon: "calendar.circle.fill", title: "Monthly Master", desc: "Complete 30 daily challenges", category: .daily) { _,_,_ in AchievementManager.dailyWins >= 30 },
        Achievement(id: "daily_100", icon: "calendar.badge.checkmark", title: "Daily Devotee", desc: "Complete 100 daily challenges", category: .daily) { _,_,_ in AchievementManager.dailyWins >= 100 },

        // Free Play
        Achievement(id: "free_1", icon: "infinity", title: "Free Spirit", desc: "Win your first free play game", category: .freeplay) { _,_,_ in AchievementManager.freePlayWins >= 1 },
        Achievement(id: "free_10", icon: "infinity.circle", title: "Freestyle Pro", desc: "Win 10 free play games", category: .freeplay) { _,_,_ in AchievementManager.freePlayWins >= 10 },
        Achievement(id: "free_50", icon: "medal.fill", title: "Free Play Legend", desc: "Win 50 free play games", category: .freeplay) { _,_,_ in AchievementManager.freePlayWins >= 50 },
        Achievement(id: "free_master", icon: "crown.fill", title: "Master Cracker", desc: "Win a Master difficulty free play", category: .freeplay) { _,_,_ in UserDefaults.standard.bool(forKey: "ach_free_master") },
        Achievement(id: "free_expert", icon: "star.square.fill", title: "Expert Cracker", desc: "Win an Expert difficulty free play", category: .freeplay) { _,_,_ in UserDefaults.standard.bool(forKey: "ach_free_expert") },

        // Duel Mode
        Achievement(id: "duel_1", icon: "person.2.fill", title: "First Duel", desc: "Win your first duel", category: .duel) { _,_,_ in AchievementManager.duelWins >= 1 },
        Achievement(id: "duel_5", icon: "person.2.circle.fill", title: "Duelist", desc: "Win 5 duels", category: .duel) { _,_,_ in AchievementManager.duelWins >= 5 },
        Achievement(id: "duel_20", icon: "person.2.badge.key.fill", title: "Duel Champion", desc: "Win 20 duels", category: .duel) { _,_,_ in AchievementManager.duelWins >= 20 },

        // Levels
        Achievement(id: "tier1", icon: "shield.fill", title: "Junior Graduate", desc: "Complete all Junior Agent levels", category: .levels) { _,p,_ in (1...40).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "tier2", icon: "shield.lefthalf.filled", title: "Agent Promoted", desc: "Complete all Agent levels", category: .levels) { _,p,_ in (41...80).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "tier3", icon: "shield.checkered", title: "Senior Agent", desc: "Complete all Senior Agent levels", category: .levels) { _,p,_ in (81...120).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "tier4", icon: "star.circle.fill", title: "Elite Agent", desc: "Complete all Elite Agent levels", category: .levels) { _,p,_ in (121...160).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "tier5", icon: "crown.fill", title: "Chief Agent", desc: "Complete all Chief Agent levels", category: .levels) { _,p,_ in (161...200).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "tier6", icon: "laurel.leading", title: "Legend", desc: "Complete all Legend Agent levels", category: .levels) { _,p,_ in (201...240).allSatisfy { p.completedLevels.contains($0) } },
        Achievement(id: "all_levels", icon: "brain.head.profile", title: "Grandmaster", desc: "Complete all 240 levels", category: .levels) { _,p,_ in p.completedLevels.count >= 240 },
        Achievement(id: "lie_10", icon: "theatermask.and.paintbrush.fill", title: "Lie Detector", desc: "Complete 10 lie mode levels", category: .levels) { _,_,lp in lp.completedLevels.count >= 10 },
        Achievement(id: "lie_30", icon: "theatermask.and.paintbrush.fill", title: "Truth Seeker", desc: "Complete 30 lie mode levels", category: .levels) { _,_,lp in lp.completedLevels.count >= 30 },

        // Stars
        Achievement(id: "star_first3", icon: "star.fill", title: "3-Star Agent", desc: "Get 3 stars on any level", category: .stars) { _,p,_ in p.starsByLevel.values.contains(3) },
        Achievement(id: "star_10", icon: "star.fill", title: "Star Collector", desc: "Earn 10 stars", category: .stars) { _,p,_ in p.totalStars >= 10 },
        Achievement(id: "star_50", icon: "star.fill", title: "Star Hunter", desc: "Earn 50 stars", category: .stars) { _,p,_ in p.totalStars >= 50 },
        Achievement(id: "star_100", icon: "diamond.fill", title: "Star Master", desc: "Earn 100 stars", category: .stars) { _,p,_ in p.totalStars >= 100 },
        Achievement(id: "star_200", icon: "diamond.fill", title: "Star Legend", desc: "Earn 200 stars", category: .stars) { _,p,_ in p.totalStars >= 200 },
        Achievement(id: "star_360", icon: "sparkles", title: "Star Hoarder", desc: "Earn 360 stars", category: .stars) { _,p,_ in p.totalStars >= 360 },
        Achievement(id: "star_720", icon: "sparkles", title: "Perfect Stars", desc: "Earn all 720 stars", category: .stars) { _,p,_ in p.totalStars >= 720 },

        // Mastery
        Achievement(id: "all_3star_t1", icon: "rosette", title: "Perfection I", desc: "3-star all Junior Agent levels", category: .mastery) { _,p,_ in (1...40).allSatisfy { (p.starsByLevel[$0] ?? 0) >= 3 } },
        Achievement(id: "all_3star_t2", icon: "rosette", title: "Perfection II", desc: "3-star all Agent levels", category: .mastery) { _,p,_ in (41...80).allSatisfy { (p.starsByLevel[$0] ?? 0) >= 3 } },
        Achievement(id: "all_3star_t3", icon: "rosette", title: "Perfection III", desc: "3-star all Senior Agent levels", category: .mastery) { _,p,_ in (81...120).allSatisfy { (p.starsByLevel[$0] ?? 0) >= 3 } },

        // Speed
        Achievement(id: "speed_1", icon: "hare.fill", title: "Lucky Guess", desc: "Crack a code in 1 attempt", category: .speed) { s,_,_ in s.gamesWon > 0 && s.totalAttempts > 0 && (Double(s.totalAttempts) / Double(s.gamesWon)) <= 1.0 || UserDefaults.standard.bool(forKey: "ach_speed_1") },
        Achievement(id: "speed_2", icon: "bolt.circle.fill", title: "Speed Cracker", desc: "Crack a code in 2 attempts", category: .speed) { _,_,_ in UserDefaults.standard.bool(forKey: "ach_speed_2") },
        Achievement(id: "speed_3", icon: "timer", title: "Quick Thinker", desc: "Crack a code in 3 attempts", category: .speed) { _,_,_ in UserDefaults.standard.bool(forKey: "ach_speed_3") },
    ]

    private init() {
        let saved = UserDefaults.standard.array(forKey: "achievements_unlocked") as? [String] ?? []
        self.unlockedIds = Set(saved)
    }

    var unlockedCount: Int { unlockedIds.count }
    var totalCount: Int { Self.all.count }

    func checkAll() {
        let stats = StatsManager.shared
        let progress = ProgressManager.shared
        let lieProgress = ProgressManager.lieShared
        for a in Self.all {
            if !unlockedIds.contains(a.id) && a.check(stats, progress, lieProgress) {
                unlockedIds.insert(a.id)
                newlyUnlocked = a
            }
        }
    }

    func markSpeedAchievement(attempts: Int) {
        if attempts <= 1 { UserDefaults.standard.set(true, forKey: "ach_speed_1") }
        if attempts <= 2 { UserDefaults.standard.set(true, forKey: "ach_speed_2") }
        if attempts <= 3 { UserDefaults.standard.set(true, forKey: "ach_speed_3") }
    }

    func markDailyWin() {
        let count = UserDefaults.standard.integer(forKey: "ach_daily_wins") + 1
        UserDefaults.standard.set(count, forKey: "ach_daily_wins")
    }

    func markFreePlayWin() {
        let count = UserDefaults.standard.integer(forKey: "ach_freeplay_wins") + 1
        UserDefaults.standard.set(count, forKey: "ach_freeplay_wins")
    }

    func markDuelWin() {
        let count = UserDefaults.standard.integer(forKey: "ach_duel_wins") + 1
        UserDefaults.standard.set(count, forKey: "ach_duel_wins")
    }

    static var dailyWins: Int { UserDefaults.standard.integer(forKey: "ach_daily_wins") }
    static var freePlayWins: Int { UserDefaults.standard.integer(forKey: "ach_freeplay_wins") }
    static var duelWins: Int { UserDefaults.standard.integer(forKey: "ach_duel_wins") }
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
