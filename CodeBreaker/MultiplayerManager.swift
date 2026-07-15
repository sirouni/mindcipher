import Foundation
import GameKit

// MARK: - Network Protocol

enum MPMessageType: String, Codable {
    case setup, progress, finished, rematch
}

struct MPMessage: Codable {
    let type: MPMessageType
    var seed: UInt64?
    var codeLength: Int?
    var colorCount: Int?
    var maxAttempts: Int?
    var allowDuplicates: Bool?
    var guessCount: Int?
    var lastExact: Int?
    var lastPartial: Int?
    var won: Bool?
    var attempts: Int?
    var elapsed: Int?
}

// MARK: - Phase

enum OnlinePhase: Equatable {
    case lobby
    case matchmaking
    case waitingSetup
    case countdown(Int)
    case playing
    case disconnected(String)
}

// MARK: - MultiplayerManager

@MainActor
class MultiplayerManager: NSObject, ObservableObject {
    @Published var phase: OnlinePhase = .lobby
    @Published var selectedDifficulty: Difficulty = .medium

    @Published var gameSeed: UInt64 = 0
    @Published var gameCodeLength: Int = 4
    @Published var gameColorCount: Int = 6
    @Published var gameMaxAttempts: Int = 9
    @Published var gameAllowDuplicates: Bool = true

    @Published var opponentName: String = ""
    @Published var opponentGuessCount: Int = 0
    @Published var opponentLastExact: Int = 0
    @Published var opponentLastPartial: Int = 0
    @Published var opponentFinished: Bool = false
    @Published var opponentWon: Bool = false
    @Published var opponentAttempts: Int = 0
    @Published var opponentElapsed: Int = 0

    private var match: GKMatch?
    private var isHost = false
    private var countdownTimer: Timer?
    private var setupRetryTimer: Timer?
    private var setupTimeoutTimer: Timer?

    // MARK: - Public API

    func findMatch() {
        guard GKLocalPlayer.local.isAuthenticated else {
            phase = .disconnected(L("online.gc.required"))
            return
        }
        phase = .matchmaking

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        guard let mmVC = GKMatchmakerViewController(matchRequest: request) else {
            phase = .lobby
            return
        }
        mmVC.matchmakerDelegate = self
        presentFromRoot(mmVC)
    }

    /// Join a match from an accepted Game Center invite. Reuses the same
    /// matchmaker delegate as findMatch(), so didFind handles host/setup.
    func acceptInvite(_ invite: GKInvite) {
        guard let mmVC = GKMatchmakerViewController(invite: invite) else {
            phase = .lobby
            return
        }
        phase = .matchmaking
        mmVC.matchmakerDelegate = self
        presentFromRoot(mmVC)
    }

    func sendProgress(guessCount: Int, exact: Int, partial: Int) {
        send(MPMessage(type: .progress, guessCount: guessCount, lastExact: exact, lastPartial: partial))
    }

    func sendFinished(won: Bool, attempts: Int, elapsed: Int) {
        send(MPMessage(type: .finished, won: won, attempts: attempts, elapsed: elapsed))
    }

    func requestRematch() {
        guard match != nil else { return }
        if case .disconnected = phase { return }
        let seed = UInt64.random(in: 1...UInt64.max)
        let d = selectedDifficulty
        let msg = MPMessage(type: .rematch, seed: seed,
                            codeLength: d.codeLength, colorCount: d.colorCount,
                            maxAttempts: d.maxAttempts, allowDuplicates: d.allowDuplicates)
        applyParams(msg)
        resetOpponent()
        send(msg)
        beginCountdown()
    }

    func disconnect() {
        countdownTimer?.invalidate()
        setupRetryTimer?.invalidate()
        setupTimeoutTimer?.invalidate()
        match?.disconnect()
        match = nil
        phase = .lobby
        resetOpponent()
    }

    // MARK: - Internal

    private func resetOpponent() {
        opponentGuessCount = 0
        opponentLastExact = 0
        opponentLastPartial = 0
        opponentFinished = false
        opponentWon = false
        opponentAttempts = 0
        opponentElapsed = 0
    }

    private func applyParams(_ msg: MPMessage) {
        if let s = msg.seed { gameSeed = s }
        if let v = msg.codeLength { gameCodeLength = v }
        if let v = msg.colorCount { gameColorCount = v }
        if let v = msg.maxAttempts { gameMaxAttempts = v }
        if let v = msg.allowDuplicates { gameAllowDuplicates = v }
    }

    private func send(_ msg: MPMessage) {
        guard let match, let data = try? JSONEncoder().encode(msg) else { return }
        try? match.sendData(toAllPlayers: data, with: .reliable)
    }

    private func receive(_ msg: MPMessage) {
        switch msg.type {
        case .setup:
            // The host re-sends setup a few times; only the first one counts.
            guard phase == .waitingSetup else { return }
            setupTimeoutTimer?.invalidate()
            applyParams(msg)
            beginCountdown()
        case .progress:
            opponentGuessCount = msg.guessCount ?? opponentGuessCount
            opponentLastExact = msg.lastExact ?? opponentLastExact
            opponentLastPartial = msg.lastPartial ?? opponentLastPartial
        case .finished:
            opponentFinished = true
            opponentWon = msg.won ?? false
            opponentAttempts = msg.attempts ?? 0
            opponentElapsed = msg.elapsed ?? 0
        case .rematch:
            applyParams(msg)
            resetOpponent()
            beginCountdown()
        }
    }

    private func beginCountdown() {
        phase = .countdown(3)
        var count = 3
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                count -= 1
                if count > 0 {
                    self.phase = .countdown(count)
                } else {
                    timer.invalidate()
                    self.phase = .playing
                }
            }
        }
    }

    // Both sides receive didFind at slightly different times; if the guest's
    // match delegate isn't set yet when setup arrives, the message is lost.
    // The host re-sends twice and the guest ignores duplicates (see receive).
    private func scheduleSetupResends(_ msg: MPMessage) {
        var remaining = 2
        setupRetryTimer?.invalidate()
        setupRetryTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self, remaining > 0 else { timer.invalidate(); return }
                remaining -= 1
                self.send(msg)
                if remaining == 0 { timer.invalidate() }
            }
        }
    }

    private func beginSetupTimeout() {
        setupTimeoutTimer?.invalidate()
        setupTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .waitingSetup else { return }
                self.match?.disconnect()
                self.match = nil
                self.phase = .disconnected(L("online.timeout"))
            }
        }
    }

    private func presentFromRoot(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        top.present(vc, animated: true)
    }
}

// MARK: - GKMatchmakerViewControllerDelegate

extension MultiplayerManager: GKMatchmakerViewControllerDelegate {
    nonisolated func matchmakerViewControllerWasCancelled(_ vc: GKMatchmakerViewController) {
        Task { @MainActor in
            vc.dismiss(animated: true)
            self.phase = .lobby
        }
    }

    nonisolated func matchmakerViewController(_ vc: GKMatchmakerViewController, didFind match: GKMatch) {
        Task { @MainActor in
            vc.dismiss(animated: true)
            self.match = match
            match.delegate = self

            if let opponent = match.players.first {
                self.opponentName = opponent.displayName
                self.isHost = GKLocalPlayer.local.teamPlayerID < opponent.teamPlayerID
            }

            if self.isHost {
                let d = self.selectedDifficulty
                let msg = MPMessage(type: .setup,
                                    seed: UInt64.random(in: 1...UInt64.max),
                                    codeLength: d.codeLength, colorCount: d.colorCount,
                                    maxAttempts: d.maxAttempts, allowDuplicates: d.allowDuplicates)
                self.applyParams(msg)
                self.send(msg)
                self.scheduleSetupResends(msg)
                self.beginCountdown()
            } else {
                self.phase = .waitingSetup
                self.beginSetupTimeout()
            }
        }
    }

    nonisolated func matchmakerViewController(_ vc: GKMatchmakerViewController, didFailWithError error: Error) {
        Task { @MainActor in
            vc.dismiss(animated: true)
            self.phase = .disconnected(error.localizedDescription)
        }
    }
}

// MARK: - GKMatchDelegate

extension MultiplayerManager: GKMatchDelegate {
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let msg = try? JSONDecoder().decode(MPMessage.self, from: data) else { return }
        Task { @MainActor in self.receive(msg) }
    }

    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .disconnected {
            Task { @MainActor in
                self.phase = .disconnected(L("online.disconnected", player.displayName))
            }
        }
    }

    nonisolated func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor in
            self.phase = .disconnected(error?.localizedDescription ?? "Connection lost")
        }
    }
}
