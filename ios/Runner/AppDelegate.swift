import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var deepLinkChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    deepLinkChannel = FlutterMethodChannel(
      name: "kz.aina/deep_links",
      binaryMessenger: controller.binaryMessenger
    )
    
    // Handle deep link if app was launched from one
    if let url = launchOptions?[.url] as? URL {
      handleDeepLink(url: url)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return handleDeepLink(url: url)
  }
  
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Handle Universal Links
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      return handleDeepLink(url: url)
    }
    return false
  }
  
  private func handleDeepLink(url: URL) -> Bool {
    print("🔗 Received deep link: \(url.absoluteString)")
    deepLinkChannel?.invokeMethod("handleDeepLink", arguments: url.absoluteString)
    return true
  }
}
