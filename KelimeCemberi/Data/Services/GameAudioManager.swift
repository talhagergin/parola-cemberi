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
        engine.mainMixerNode.outputVolume = 1
        player.volume = 1
        restartIfPossible()
    }

    func play(_ event: GameSoundEvent, enabled: Bool) {
        guard enabled else { return }
        if !isReady || !engine.isRunning { restartIfPossible() }
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
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            engine.prepare()
            try engine.start()
            isReady = true
        } catch {
            // Missing audio hardware or an interrupted session must never block gameplay.
            isReady = false
        }
    }

    private func tones(for event: GameSoundEvent) -> [(frequency: Double, duration: Double, volume: Float)] {
        switch event {
        case .correct: [(660, 0.09, 0.46), (880, 0.16, 0.52)]
        case .wrong: [(220, 0.16, 0.48), (165, 0.24, 0.42)]
        case .passed: [(420, 0.09, 0.38), (330, 0.14, 0.34)]
        case .hint: [(520, 0.08, 0.36), (700, 0.14, 0.42)]
        case .streak: [(660, 0.08, 0.42), (830, 0.08, 0.47), (1_050, 0.22, 0.54)]
        case .timeWarning: [(780, 0.10, 0.44), (780, 0.10, 0.44), (980, 0.16, 0.50)]
        case .roundCompleted: [(523, 0.11, 0.42), (659, 0.11, 0.46), (784, 0.11, 0.50), (1_047, 0.30, 0.56)]
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
