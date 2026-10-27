import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var soundPlayers: [String: AVAudioPlayer] = [:]
  private var currentSound: AVAudioPlayer?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ParolaAudio") else { return }
    let channel = FlutterMethodChannel(name: "parola/audio", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      do {
        if call.method == "prepare" {
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
          try session.setActive(true)
          for event in ["correct", "wrong", "pass", "hint", "streak", "warning", "complete"] {
            let key = registrar.lookupKey(forAsset: "assets/audio/\(event).wav")
            guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
              result(FlutterError(code: "asset_missing", message: key, details: nil)); return
            }
            let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player.volume = 0.75
            player.prepareToPlay()
            self.soundPlayers[event] = player
          }
          result(nil)
        } else if call.method == "play", let event = call.arguments as? String,
                  let player = self.soundPlayers[event] {
          self.currentSound?.stop()
          player.currentTime = 0
          self.currentSound = player
          guard player.play() else {
            result(FlutterError(code: "play_failed", message: event, details: nil)); return
          }
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "audio_error", message: error.localizedDescription, details: nil))
      }
    }
  }
}
