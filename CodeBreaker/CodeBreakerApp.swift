import SwiftUI
import GameKit

@main
struct CodeBreakerApp: App {
    @State private var showSplash = true
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var challengeManager = ChallengeManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .sheet(item: $challengeManager.pendingChallenge) { challenge in
                        NavigationStack {
                            ChallengeGameView(challenge: challenge)
                        }
                    }
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
            .onOpenURL { url in
                ChallengeManager.shared.handleURL(url)
            }
        }
    }
}

// MARK: - Challenge Manager

struct Challenge: Identifiable {
    let id = UUID()
    let secretCode: [PegColor]
    let colorCount: Int
    let maxAttempts: Int
    let fromName: String
}

class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    @Published var pendingChallenge: Challenge?

    func handleURL(_ url: URL) {
        guard url.scheme == "codebreaker",
              url.host == "challenge",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return }

        let codeStr = items.first { $0.name == "code" }?.value ?? ""
        let colorsCount = Int(items.first { $0.name == "colors" }?.value ?? "6") ?? 6
        let attempts = Int(items.first { $0.name == "attempts" }?.value ?? "7") ?? 7
        let from = items.first { $0.name == "from" }?.value ?? "A friend"

        let code = codeStr.compactMap { c -> PegColor? in
            guard let idx = Int(String(c)), idx < PegColor.allCases.count else { return nil }
            return PegColor(rawValue: idx)
        }
        guard !code.isEmpty else { return }

        DispatchQueue.main.async {
            self.pendingChallenge = Challenge(
                secretCode: code,
                colorCount: colorsCount,
                maxAttempts: attempts,
                fromName: from
            )
        }
    }

    func generateChallengeURL(secretCode: [PegColor], colorCount: Int, maxAttempts: Int, playerName: String) -> URL {
        let codeStr = secretCode.map { String($0.rawValue) }.joined()
        let name = playerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Agent"
        var components = URLComponents()
        components.scheme = "codebreaker"
        components.host = "challenge"
        components.queryItems = [
            URLQueryItem(name: "code", value: codeStr),
            URLQueryItem(name: "colors", value: "\(colorCount)"),
            URLQueryItem(name: "attempts", value: "\(maxAttempts)"),
            URLQueryItem(name: "from", value: name),
        ]
        return components.url!
    }
}

// MARK: - Challenge Game View

struct ChallengeGameView: View {
    let challenge: Challenge
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var started = false

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            if !started {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.accent)

                    Text("Challenge from")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(challenge.fromName)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Code length")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("\(challenge.secretCode.count)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        HStack {
                            Text("Colors")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("\(challenge.colorCount)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        HStack {
                            Text("Max attempts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("\(challenge.maxAttempts)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .padding(20)
                    .glassCard(cornerRadius: 16)

                    Text("Can you crack their code?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    Button {
                        viewModel.startDuel(
                            secretCode: challenge.secretCode,
                            colorCount: challenge.colorCount,
                            maxAttempts: challenge.maxAttempts
                        )
                        started = true
                    } label: {
                        Text("Accept Challenge")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(24)
            }
        }
        .navigationDestination(isPresented: $started) {
            GameView(viewModel: viewModel)
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
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
