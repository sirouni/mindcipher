import SwiftUI
import GameKit

@main
struct CodeBreakerApp: App {
    @State private var showSplash = true
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                if showSplash {
                    SplashView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .preferredColorScheme(.light)
            .id(themeManager.currentSkin.rawValue)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    showSplash = false
                }
                GameCenterManager.shared.authenticate()
            }
        }
    }
}

// MARK: - Game Center Manager

class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()
    static let dailyLeaderboardID = "com.codebreaker.app.daily"

    @Published var isAuthenticated = false

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
            if let error {
                print("Game Center auth failed: \(error.localizedDescription)")
            }
        }
    }

    func submitDailyScore(attempts: Int, maxAttempts: Int, elapsedSeconds: Int) {
        guard isAuthenticated else { return }
        let score = (maxAttempts - attempts) * 10000 + max(0, 10000 - elapsedSeconds)
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.dailyLeaderboardID]
        ) { error in
            if let error {
                print("Score submission failed: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else { return }
        let gcVC = GKGameCenterViewController(leaderboardID: Self.dailyLeaderboardID,
                                              playerScope: .global,
                                              timeScope: .today)
        gcVC.gameCenterDelegate = GameCenterDismissHandler.shared
        viewController.present(gcVC, animated: true)
    }
}

class GameCenterDismissHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissHandler()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
