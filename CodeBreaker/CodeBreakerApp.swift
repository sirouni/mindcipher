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

// m (mode flags): bit 0 = lie, bits 1-7 reserved for future modes
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

    func handleURL(_ url: URL) {
        guard url.scheme == "codebreaker",
              url.host == "challenge",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return }

        guard let seedStr = items.first(where: { $0.name == "s" })?.value,
              let seed = UInt64(seedStr), seed != 0 else { return }

        let len = Int(items.first { $0.name == "l" }?.value ?? "4") ?? 4
        let colors = Int(items.first { $0.name == "c" }?.value ?? "6") ?? 6
        let attempts = Int(items.first { $0.name == "a" }?.value ?? "7") ?? 7
        let dup = (items.first { $0.name == "d" }?.value ?? "0") == "1"
        let modeRaw = Int(items.first { $0.name == "m" }?.value ?? "0") ?? 0
        let mode = ChallengeMode(rawValue: modeRaw) ?? .classic
        let from = items.first { $0.name == "f" }?.value ?? "A friend"

        DispatchQueue.main.async {
            self.pendingChallenge = Challenge(
                seed: seed,
                codeLength: len,
                colorCount: colors,
                allowDuplicates: dup,
                maxAttempts: attempts,
                challengeMode: mode,
                fromName: from
            )
        }
    }

    func generateChallengeURL(seed: UInt64, codeLength: Int, colorCount: Int, allowDuplicates: Bool, maxAttempts: Int, mode: ChallengeMode = .classic, playerName: String) -> URL {
        let name = playerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Agent"
        var components = URLComponents()
        components.scheme = "codebreaker"
        components.host = "challenge"
        components.queryItems = [
            URLQueryItem(name: "s", value: "\(seed)"),
            URLQueryItem(name: "l", value: "\(codeLength)"),
            URLQueryItem(name: "c", value: "\(colorCount)"),
            URLQueryItem(name: "a", value: "\(maxAttempts)"),
            URLQueryItem(name: "d", value: allowDuplicates ? "1" : "0"),
            URLQueryItem(name: "m", value: "\(mode.rawValue)"),
            URLQueryItem(name: "f", value: name),
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
        Group {
            if started {
                GameView(viewModel: viewModel)
            } else {
                ZStack {
                    AppTheme.bgGradient.ignoresSafeArea()

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
                                Text("\(challenge.codeLength)")
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

                        if challenge.challengeMode == .lie {
                            Label("Lie Mode — one feedback may be fake!", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.danger)
                        }

                        Text("Can you crack their code?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                        Spacer()

                        Button {
                            viewModel.startChallenge(
                                seed: challenge.seed,
                                codeLength: challenge.codeLength,
                                colorCount: challenge.colorCount,
                                allowDuplicates: challenge.allowDuplicates,
                                maxAttempts: challenge.maxAttempts,
                                lieMode: challenge.challengeMode == .lie
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
