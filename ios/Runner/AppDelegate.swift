import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let pttChannelName = "com.pwseries/ptt"
  private var audioEngine: AVAudioEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Canal para PTT
    if let controller = window?.rootViewController as? FlutterViewController {
      let pttChannel = FlutterMethodChannel(
        name: pttChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      pttChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "requestMicPermission":
          AVCaptureDevice.requestAccess(for: .audio) { granted in
            result(granted)
          }

        case "pttStart":
          self?.startPTT(result: result)

        case "pttStop":
          self?.stopPTT(result: result)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startPTT(result: FlutterResult) {
    do {
      // Categoría para capturar y reproducir por altavoz (sin Bluetooth Classic)
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth] // A2DP no aplica para grabación + reproducción simultánea
      )
      try AVAudioSession.sharedInstance().setActive(true, options: [])

      let engine = AVAudioEngine()
      let input = engine.inputNode
      let output = engine.outputNode
      let format = input.inputFormat(forBus: 0)

      // Passthrough simple: mic -> speaker
      engine.connect(input, to: output, format: format)

      // Si quieres observar buffers, puedes instalar un tap:
      // input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      //   // procesar si se requiere
      // }

      engine.prepare()
      try engine.start()
      self.audioEngine = engine

      result(true)
    } catch {
      result(FlutterError(code: "PTT_START_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func stopPTT(result: FlutterResult) {
    if let engine = audioEngine {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
      audioEngine = nil
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    result(true)
  }
}

