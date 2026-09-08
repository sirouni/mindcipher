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

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

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
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(AppTheme.ink.opacity(0.12)).frame(width: 80, height: 80)
                    Image(systemName: "wifi")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.ink)
                }
                Text(L("online.title"))
                    .font(AppFont.display(24, weight: .black))
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
                .font(AppFont.display(17, weight: .bold))
                .foregroundStyle(AppTheme.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    GameCenterManager.shared.isAuthenticated ? AppTheme.ink : AppTheme.ink.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 4)
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
                        Text(diff.localizedName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(manager.selectedDifficulty == diff ? AppTheme.paper : AppTheme.textPrimary)
                        Spacer()
                        Text(diff.statsLabel)
                            .font(AppFont.mono(12, weight: .medium))
                            .foregroundStyle(manager.selectedDifficulty == diff ? AppTheme.paper.opacity(0.8) : AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(manager.selectedDifficulty == diff ? AppTheme.ink : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .paperCard()
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill").foregroundStyle(AppTheme.ink)
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
        .paperCard()
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
            ProgressView().scaleEffect(1.5).tint(AppTheme.ink)
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(AppFont.display(17, weight: .bold))
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
                    .font(AppFont.display(22, weight: .black))
                    .foregroundStyle(AppTheme.textMuted)
                playerAvatar(name: manager.opponentName, isLocal: false)
            }

            Text(manager.selectedDifficulty.localizedName)
                .font(AppFont.mono(14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .paperCard()

            ZStack {
                Circle()
                    .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: CGFloat(count) / 3.0)
                    .stroke(AppTheme.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                Text("\(count)")
                    .font(AppFont.display(48, weight: .black))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer()
        }
    }

    private func playerAvatar(name: String, isLocal: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((isLocal ? AppTheme.ink : AppTheme.warning).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isLocal ? AppTheme.ink : AppTheme.warning)
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
                .foregroundStyle(AppTheme.paper.opacity(0.8))

            Text(manager.opponentName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.paper)
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
                .fill(AppTheme.ink.opacity(0.9))
        )
    }

    @ViewBuilder
    private var opponentResultBadge: some View {
        if manager.opponentWon {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                Text("\(manager.opponentAttempts) \(L("online.steps"))")
                    .font(AppFont.mono(11, weight: .bold))
            }
            .foregroundStyle(AppTheme.paper)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 11))
                Text(L("result.lose"))
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(AppTheme.accent)
        }
    }

    private var opponentProgressBadge: some View {
        HStack(spacing: 4) {
            Text("\(manager.opponentGuessCount)/\(manager.gameMaxAttempts)")
                .font(AppFont.mono(11, weight: .bold))
                .foregroundStyle(AppTheme.paper.opacity(0.9))

            if manager.opponentGuessCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<manager.opponentLastExact, id: \.self) { _ in
                        Circle().fill(AppTheme.paper).frame(width: 6, height: 6)
                    }
                    ForEach(0..<manager.opponentLastPartial, id: \.self) { _ in
                        Circle().stroke(AppTheme.paper, lineWidth: 1.5).frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Comparison Overlay

    private var comparisonOverlay: some View {
        ZStack {
            AppTheme.ink.opacity(0.45).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 20) {
                Text(resultTitle)
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(resultColor)

                HStack(spacing: 20) {
                    resultColumn(
                        name: GKLocalPlayer.local.displayName,
                        won: localWon, attempts: localAttempts, elapsed: localElapsed,
                        isWinner: iWon
                    )

                    VStack {
                        Text("VS")
                            .font(AppFont.display(16, weight: .black))
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
                .paperCard()

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
                            .font(AppFont.display(17, weight: .bold))
                            .foregroundStyle(AppTheme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
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
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.bgCardLight)
            )
            .padding(24)
        }
    }

    private func resultColumn(name: String, won: Bool, attempts: Int, elapsed: Int, isWinner: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill((isWinner ? AppTheme.ink : AppTheme.textMuted).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(won ? AppTheme.ink : AppTheme.danger)
            }

            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 100)

            if won {
                Text("\(attempts) \(L("online.steps"))")
                    .font(AppFont.mono(15, weight: .black))
                    .foregroundStyle(AppTheme.ink)
            } else {
                Text(L("result.lose"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
            }

            Text("\(elapsed)s")
                .font(AppFont.mono(12, weight: .medium))
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
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppTheme.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
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
        return iWon ? AppTheme.ink : AppTheme.danger
    }
}
