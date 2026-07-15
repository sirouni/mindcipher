import SwiftUI
import GameKit

struct MultiplayerView: View {
    @StateObject private var manager = MultiplayerManager()
    @StateObject private var viewModel = GameViewModel()
    @ObservedObject private var gcManager = GameCenterManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var localFinished = false
    @State private var localWon = false
    @State private var localAttempts = 0
    @State private var localElapsed = 0
    @State private var showComparison = false
    @State private var gameRound = 0

    private let accent = Color(red: 0.2, green: 0.8, blue: 0.6)

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            switch manager.phase {
            case .lobby:
                lobbyView
            case .matchmaking:
                statusView(icon: "antenna.radiowaves.left.and.right",
                           title: L("online.searching"),
                           showCancel: true)
            case .waitingSetup:
                statusView(icon: "ellipsis.circle",
                           title: L("online.waiting"),
                           subtitle: manager.opponentName.isEmpty ? nil : "vs \(manager.opponentName)",
                           showCancel: false)
            case .countdown(let n):
                countdownView(n)
            case .playing:
                gamePlayView
            case .disconnected(let msg):
                disconnectedView(msg)
            }

            if showComparison {
                comparisonOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(200)
            }
        }
        .navigationBarBackButtonHidden(manager.phase != .lobby)
        .onAppear { consumePendingInvite() }
        .onReceive(gcManager.$pendingInvite) { _ in consumePendingInvite() }
        .onChange(of: manager.phase) { _, newPhase in
            if case .playing = newPhase {
                startNewRound()
            }
        }
        .onChange(of: manager.opponentFinished) { _, finished in
            if finished { tryShowComparison() }
        }
    }

    /// If the player arrived here by accepting an invite, join that match.
    private func consumePendingInvite() {
        guard let invite = gcManager.pendingInvite, manager.phase == .lobby else { return }
        gcManager.pendingInvite = nil
        manager.acceptInvite(invite)
    }

    // MARK: - Lobby

    private var lobbyView: some View {
        VStack(spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 80, height: 80)
                    Image(systemName: "wifi")
                        .font(.system(size: 36))
                        .foregroundStyle(accent)
                }
                Text(L("online.title"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L("online.desc"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            difficultyPicker

            rulesCard

            Spacer()

            Button { manager.findMatch() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text(L("online.find"))
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    GameCenterManager.shared.isAuthenticated ? accent : accent.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }

            if !GameCenterManager.shared.isAuthenticated {
                Text(L("online.gc.required"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .padding(24)
    }

    private var difficultyPicker: some View {
        VStack(spacing: 8) {
            ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                Button {
                    withAnimation(.spring(response: 0.3)) { manager.selectedDifficulty = diff }
                } label: {
                    HStack {
                        Text(diff.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(manager.selectedDifficulty == diff ? .white : AppTheme.textPrimary)
                        Spacer()
                        Text("\(diff.codeLength)×\(diff.colorCount)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(manager.selectedDifficulty == diff ? .white.opacity(0.8) : AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(manager.selectedDifficulty == diff ? accent : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .glassCard()
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill").foregroundStyle(accent)
                Text(L("online.rules.title"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                ruleRow(L("online.rule1"))
                ruleRow(L("online.rule2"))
                ruleRow(L("online.rule3"))
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private func ruleRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppTheme.textSecondary)
    }

    // MARK: - Status / Waiting

    private func statusView(icon: String, title: String, subtitle: String? = nil, showCancel: Bool) -> some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().scaleEffect(1.5).tint(accent)
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(accent)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            if showCancel {
                Button { manager.disconnect() } label: {
                    Text(L("result.back"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Countdown

    private func countdownView(_ count: Int) -> some View {
        VStack(spacing: 28) {
            Spacer()

            HStack(spacing: 30) {
                playerAvatar(name: GKLocalPlayer.local.displayName, isLocal: true)
                Text("VS")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
                playerAvatar(name: manager.opponentName, isLocal: false)
            }

            Text(manager.selectedDifficulty.rawValue)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCard(cornerRadius: 8)

            ZStack {
                Circle()
                    .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: CGFloat(count) / 3.0)
                    .stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                Text("\(count)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            Spacer()
        }
    }

    private func playerAvatar(name: String, isLocal: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((isLocal ? accent : AppTheme.warning).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isLocal ? accent : AppTheme.warning)
            }
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }

    // MARK: - Gameplay

    private var gamePlayView: some View {
        ZStack(alignment: .top) {
            GameView(viewModel: viewModel)
                .id(gameRound)
                .onChange(of: viewModel.guessHistory.count) { _, _ in
                    guard let last = viewModel.guessHistory.last else { return }
                    manager.sendProgress(
                        guessCount: viewModel.guessHistory.count,
                        exact: last.feedback.exact,
                        partial: last.feedback.partial
                    )
                }
                .onChange(of: viewModel.phase) { _, newPhase in
                    handleGameEnd(newPhase)
                }

            opponentBar
                .padding(.top, 52)
                .padding(.horizontal, 16)
        }
    }

    private var opponentBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.8))

            Text(manager.opponentName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            if manager.opponentFinished {
                opponentResultBadge
            } else {
                opponentProgressBadge
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
    }

    @ViewBuilder
    private var opponentResultBadge: some View {
        if manager.opponentWon {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                Text("\(manager.opponentAttempts) \(L("online.steps"))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color(red: 0.3, green: 1.0, blue: 0.5))
        } else {
            HStack(spacing: 3) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 11))
                Text(L("result.lose"))
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
        }
    }

    private var opponentProgressBadge: some View {
        HStack(spacing: 4) {
            Text("\(manager.opponentGuessCount)/\(manager.gameMaxAttempts)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))

            if manager.opponentGuessCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<manager.opponentLastExact, id: \.self) { _ in
                        Circle().fill(accent).frame(width: 6, height: 6)
                    }
                    ForEach(0..<manager.opponentLastPartial, id: \.self) { _ in
                        FeedbackTriangle().fill(AppTheme.warning).frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Comparison Overlay

    private var comparisonOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 20) {
                Text(resultTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(resultColor)

                HStack(spacing: 20) {
                    resultColumn(
                        name: GKLocalPlayer.local.displayName,
                        won: localWon, attempts: localAttempts, elapsed: localElapsed,
                        isWinner: iWon
                    )

                    VStack {
                        Text("VS")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    resultColumn(
                        name: manager.opponentName,
                        won: manager.opponentWon, attempts: manager.opponentAttempts,
                        elapsed: manager.opponentElapsed,
                        isWinner: !iWon && !isDraw
                    )
                }
                .padding(20)
                .glassCard()

                VStack(spacing: 10) {
                    if case .disconnected = manager.phase {
                        HStack(spacing: 6) {
                            Image(systemName: "wifi.slash")
                            Text(L("online.opponent.left"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    } else {
                        Button {
                            withAnimation { showComparison = false }
                            localFinished = false
                            manager.requestRematch()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text(L("online.rematch"))
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        manager.disconnect()
                        dismiss()
                    } label: {
                        Text(L("online.exit"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.15), radius: 20)
            )
            .padding(24)
        }
    }

    private func resultColumn(name: String, won: Bool, attempts: Int, elapsed: Int, isWinner: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill((isWinner ? accent : AppTheme.textMuted).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(won ? accent : AppTheme.danger)
            }

            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 100)

            if won {
                Text("\(attempts) \(L("online.steps"))")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
            } else {
                Text(L("result.lose"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
            }

            Text("\(elapsed)s")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)

            if isWinner {
                Text("👑")
                    .font(.system(size: 20))
            }
        }
    }

    // MARK: - Disconnected

    private func disconnectedView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.danger)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                manager.disconnect()
                dismiss()
            } label: {
                Text(L("result.back"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
    }

    // MARK: - Logic

    private func startNewRound() {
        localFinished = false
        showComparison = false
        gameRound += 1
        viewModel.startOnlineGame(
            seed: manager.gameSeed,
            codeLength: manager.gameCodeLength,
            colorCount: manager.gameColorCount,
            maxAttempts: manager.gameMaxAttempts,
            allowDuplicates: manager.gameAllowDuplicates
        )
    }

    private func handleGameEnd(_ phase: GamePhase) {
        switch phase {
        case .won(let attempts):
            localFinished = true
            localWon = true
            localAttempts = attempts
            localElapsed = Int(Date().timeIntervalSince(viewModel.gameStartTime ?? Date()))
            manager.sendFinished(won: true, attempts: attempts, elapsed: localElapsed)
            tryShowComparison()
        case .lost:
            localFinished = true
            localWon = false
            localAttempts = viewModel.guessHistory.count
            localElapsed = Int(Date().timeIntervalSince(viewModel.gameStartTime ?? Date()))
            manager.sendFinished(won: false, attempts: localAttempts, elapsed: localElapsed)
            tryShowComparison()
        default:
            break
        }
    }

    private func tryShowComparison() {
        guard localFinished, manager.opponentFinished else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5)) { showComparison = true }
        }
    }

    // MARK: - Result Helpers

    private var iWon: Bool {
        if localWon && !manager.opponentWon { return true }
        if !localWon && manager.opponentWon { return false }
        if localWon && manager.opponentWon {
            if localAttempts < manager.opponentAttempts { return true }
            if localAttempts == manager.opponentAttempts { return localElapsed < manager.opponentElapsed }
        }
        return false
    }

    private var isDraw: Bool {
        localWon == manager.opponentWon
            && localAttempts == manager.opponentAttempts
            && localElapsed == manager.opponentElapsed
    }

    private var resultTitle: String {
        if isDraw { return L("online.draw") }
        return iWon ? L("online.you.win") : L("online.you.lose")
    }

    private var resultColor: Color {
        if isDraw { return AppTheme.warning }
        return iWon ? accent : AppTheme.danger
    }
}
