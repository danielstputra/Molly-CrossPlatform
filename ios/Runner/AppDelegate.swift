import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let bgChannel = FlutterMethodChannel(name: "com.molly.crossplatform/background_service",
                                         binaryMessenger: controller.binaryMessenger)

    bgChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      
      switch call.method {
      case "startBackgroundTask":
        let title = (call.arguments as? [String: Any])?["title"] as? String ?? "Molly AI"
        self.beginBackgroundKeepAlive()
        result(true)

      case "stopBackgroundTask":
        self.endBackgroundKeepAlive()
        result(true)

      case "showNotification":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let body = args["body"] as? String {
          let type = args["type"] as? String ?? "info"
          self.scheduleLocalNotification(type: type, title: title, body: body)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing title or body", details: nil))
        }

      case "requestPermissions":
        self.requestNotificationPermissions { granted in
          result(granted)
        }

      case "checkBatteryOptimizations":
        result(true)

      case "requestIgnoreBatteryOptimizations":
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func beginBackgroundKeepAlive() {
    endBackgroundKeepAlive()
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "MollyAgentTaskKeepAlive") { [weak self] in
      self?.endBackgroundKeepAlive()
    }
  }

  private func endBackgroundKeepAlive() {
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
      backgroundTaskId = .invalid
    }
  }

  private func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    } else {
      completion(true)
    }
  }

  private func scheduleLocalNotification(type: String, title: String, body: String) {
    if #available(iOS 10.0, *) {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = UNNotificationSound.default

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
      let request = UNNotificationRequest(identifier: "molly_\(type)_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
