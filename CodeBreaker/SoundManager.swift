import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isAudioReady = false

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        guard let engine = audioEngine, let player = playerNode else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            isAudioReady = true
        } catch {
            isAudioReady = false
        }
    }

    private var haptics: Bool { AppSettings.shared.hapticsEnabled }
    private var sound: Bool { AppSettings.shared.soundEnabled }

    func playTap() {
        if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func playPlace() {
        if haptics { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        if sound { playTone(frequency: 880, duration: 0.05) }
    }

    func playSubmit() {
        if haptics { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        if sound { playMorseSequence([.short, .short, .long]) }
    }

    func playWin() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        if sound { playVictoryJingle() }
    }

    func playLose() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        if sound { playTone(frequency: 220, duration: 0.4) }
    }

    func playError() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    }

    func playLieSubmit() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        if sound { playMorseSequence([.short, .long, .short]) }
    }

    func playLieReveal() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        if sound {
            playTone(frequency: 392, duration: 0.08)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.playTone(frequency: 311, duration: 0.1)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
                self?.playTone(frequency: 523, duration: 0.18, volume: 0.16)
            }
        }
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Double, duration: Double, volume: Float = 0.15) {
        guard isAudioReady, let player = playerNode else { return }
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t / 0.005, (duration - t) / 0.01))
            data[i] = Float(sin(2.0 * .pi * frequency * t) * envelope * Double(volume))
        }

        player.scheduleBuffer(buffer, at: nil)
        if !player.isPlaying { player.play() }
    }

    enum MorseUnit { case short, long, pause }

    private func playMorseSequence(_ units: [MorseUnit]) {
        var delay: Double = 0
        for unit in units {
            let dur: Double
            let freq: Double = 700
            switch unit {
            case .short: dur = 0.06
            case .long: dur = 0.16
            case .pause: dur = 0.1; delay += dur; continue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: dur, volume: 0.12)
            }
            delay += dur + 0.06
        }
    }

    private func playVictoryJingle() {
        let notes: [(Double, Double)] = [
            (523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.2)
        ]
        var delay: Double = 0
        for (freq, dur) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: dur, volume: 0.15)
            }
            delay += dur + 0.05
        }
    }
}
