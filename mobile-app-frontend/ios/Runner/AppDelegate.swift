import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle deep links when app is opened from another app (e.g., MetaMask)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Let Flutter handle the URL through the url_launcher plugin
    // This allows the app to be opened from MetaMask after transaction approval
    return super.application(app, open: url, options: options)
  }
  
  // Handle Universal Links (if needed in the future)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Handle Universal Links if needed
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
