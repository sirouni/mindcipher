import SwiftUI
import StoreKit

@main
struct CodeBreakerClipApp: App {
    @State private var challenge: Challenge?
    @State private var viewModel = GameViewModel()
    @State private var gameStarted = false
    @State private var showOverlay = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let challenge = challenge {
                    if gameStarted {
                        GameView(viewModel: viewModel)
                            .overlay(alignment: .bottom) {
                                appStoreOverlay
                            }
                    } else {
                        challengePreview(challenge)
                    }
                } else {
                    welcomeView
                }
            }
            .preferredColorScheme(.light)
            .onOpenURL { url in
                handleURL(url)
            }
            .onAppear {
                handleLaunchURL()
            }
        }
    }

    private var welcomeView: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)

                Text("Mind Cipher")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Open a challenge link to play!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                downloadButton
            }
            .padding(24)
        }
    }

    private func challengePreview(_ challenge: Challenge) -> some View {
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
                    infoRow("Code length", "\(challenge.codeLength)")
                    infoRow("Colors", "\(challenge.colorCount)")
                    infoRow("Max attempts", "\(challenge.maxAttempts)")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.55))
                )

                if challenge.challengeMode == .lie {
                    Label("Lie Mode", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                }

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
                    gameStarted = true
                } label: {
                    Text("Accept Challenge")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                }

                downloadButton
            }
            .padding(24)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var downloadButton: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/app/mind-cipher/id6777428188") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 14))
                Text("Get Full App")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppTheme.warning)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.warning, lineWidth: 1.5)
            )
        }
    }

    @ViewBuilder
    private var appStoreOverlay: some View {
        if showOverlay {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mind Cipher")
                            .font(.system(size: 14, weight: .bold))
                        Text("Get the full experience")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        if let url = URL(string: "https://apps.apple.com/app/mind-cipher/id6777428188") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("GET")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(AppTheme.accent, in: Capsule())
                    }
                    Button {
                        withAnimation { showOverlay = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
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

        challenge = Challenge(
            seed: seed, codeLength: len, colorCount: colors,
            allowDuplicates: dup, maxAttempts: attempts,
            challengeMode: mode, fromName: from
        )
    }

    private func handleLaunchURL() {
        guard let url = URLComponents(string: ProcessInfo.processInfo.environment["_XCWidgetDefaultView"] ?? "") else { return }
    }
}
