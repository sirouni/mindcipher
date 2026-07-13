import SwiftUI
import Foundation

// Stubs for types referenced by shared source files but not needed in App Clip.

enum ChallengeMode: Int {
    case classic = 0
    case lie = 1
}

struct Challenge: Identifiable {
    let id = UUID()
    let seed: UInt64
    let codeLength: Int
    let colorCount: Int
    let allowDuplicates: Bool
    let maxAttempts: Int
    let challengeMode: ChallengeMode
    let fromName: String
}

class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    @Published var pendingChallenge: Challenge?
    func handleURL(_ url: URL) {}
    func generateChallengeURL(seed: UInt64, codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, mode: ChallengeMode = .classic, playerName: String) -> URL {
        URL(string: "https://sirouni.github.io/challenge")!
    }
}

class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()
    static let totalLeaderboardID = "com.codebreaker.app.total"
    @Published var isAuthenticated = false
    func authenticate() {}
    func submitDailyScore(dateKey: String, attempts: Int, maxAttempts: Int, elapsedSeconds: Int) {}
    func submitTotalScore() {}
}

class DailyStreakManager {
    static let shared = DailyStreakManager()
    var completedDates: Set<String> { [] }
    var totalCompleted: Int { 0 }
    var currentStreak: Int { 0 }
    func markCompleted(date: String) {}
    func isCompleted(_ date: String) -> Bool { false }
    func saveResult(date: String, won: Bool, attempts: Int, elapsedSeconds: Int) {}
    func result(for date: String) -> (won: Bool, attempts: Int, time: Int)? { nil }
    static var dayNumber: Int { 1 }
    func scheduleStreakReminder() {}
}

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    static let freeLevelCap = 80
    @Published var isPro: Bool = false
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    var soundEnabled: Bool { false }
    var hapticsEnabled: Bool { false }
}

enum AppSkin: String, CaseIterable {
    case classic
    var accent: Color { Color(red: 0.05, green: 0.60, blue: 0.55) }
    var bgColors: (Color, Color) {
        (Color(red: 0.91, green: 0.94, blue: 0.97), Color(red: 0.88, green: 0.92, blue: 0.96))
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentSkin: AppSkin = .classic
}

extension Notification.Name {
    static let openDailyChallenge = Notification.Name("openDailyChallenge")
}
