import AVFoundation
import Foundation

enum GameSoundEvent: Sendable {
    case correct, wrong, passed, hint, streak, timeWarning, roundCompleted
}

@MainActor
protocol AudioManaging: AnyObject {
    func play(_ event: GameSoundEvent, enabled: Bool)
}

@MainActor
final class GameAudioManager: AudioManaging {
    static let shared = GameAudioManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var isReady = false

    private init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            isReady = true
        } catch {
            // Missing audio hardware or an interrupted session must never block gameplay.
            isReady = false
        }
    }

    func play(_ event: GameSoundEvent, enabled: Bool) {
        guard enabled else { return }
        if !isReady { restartIfPossible() }
        guard isReady else { return }

        player.stop()
        for tone in tones(for: event) {
            guard let buffer = makeBuffer(frequency: tone.frequency, duration: tone.duration, volume: tone.volume) else { continue }
            player.scheduleBuffer(buffer)
        }
        player.play()
    }

    private func restartIfPossible() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isReady = true
        } catch { isReady = false }
    }

    private func tones(for event: GameSoundEvent) -> [(frequency: Double, duration: Double, volume: Float)] {
        switch event {
        case .correct: [(660, 0.08, 0.25), (880, 0.13, 0.30)]
        case .wrong: [(220, 0.14, 0.28), (165, 0.20, 0.24)]
        case .passed: [(420, 0.07, 0.20), (330, 0.10, 0.18)]
        case .hint: [(520, 0.06, 0.18), (700, 0.10, 0.22)]
        case .streak: [(660, 0.07, 0.22), (830, 0.07, 0.25), (1_050, 0.18, 0.30)]
        case .timeWarning: [(780, 0.08, 0.22), (780, 0.08, 0.22), (980, 0.12, 0.25)]
        case .roundCompleted: [(523, 0.09, 0.22), (659, 0.09, 0.24), (784, 0.09, 0.26), (1_047, 0.25, 0.30)]
        }
    }

    private func makeBuffer(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
            let attack = min(1, progress / 0.08)
            let release = min(1, (1 - progress) / 0.18)
            let envelope = Float(max(0, min(attack, release)))
            samples[frame] = sin(Float(2 * Double.pi * frequency * Double(frame) / sampleRate)) * volume * envelope
        }
        return buffer
    }
}
