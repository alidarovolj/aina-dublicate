import Flutter
import UIKit
import EpaySDK

@objc public class EpayPlugin: NSObject {
    private var viewController: UIViewController
    private var pendingResult: FlutterResult?
    private var paymentTimer: Timer?
    private var loadingStateTimer: Timer?
    private var loadingStateCount: Int = 0
    
    private let kPaymentNotification = "payment_notification"
    private let kLoadingNotification = "payment_loading_notification"
    private let kErrorNotification = "payment_error_notification"
    private let kTimeoutNotification = "payment_timeout_notification"
    private let kCancelledNotification = "payment_cancelled_notification"
    
    @objc public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        NSLog("📱 EpayPlugin initialized")
        
        // Add observer for SDK response
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSdkResponse),
            name: NSNotification.Name("sdk_response"),
            object: nil
        )
        NSLog("📱 Added observer for sdk_response notification")
        
        // Add observer for payment completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSdkResponse),
            name: NSNotification.Name("payment_completed"),
            object: nil
        )
        NSLog("📱 Added observer for payment_completed notification")
        
        // Add observer for payment error
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSdkResponse),
            name: NSNotification.Name("payment_error"),
            object: nil
        )
        NSLog("📱 Added observer for payment_error notification")
        
        // Add observer for payment cancellation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSdkResponse),
            name: NSNotification.Name("payment_cancelled"),
            object: nil
        )
        NSLog("📱 Added observer for payment_cancelled notification")
        
        // Add observer for payment timeout
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSdkResponse),
            name: NSNotification.Name("payment_timeout"),
            object: nil
        )
        NSLog("📱 Added observer for payment_timeout notification")
        
        // Add observer for loading state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoadingState),
            name: NSNotification.Name("loading_state_changed"),
            object: nil
        )
        NSLog("📱 Added observer for loading state changes")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        paymentTimer?.invalidate()
        loadingStateTimer?.invalidate()
        NSLog("📱 EpayPlugin deinitialized")
    }
    
    @objc private func handleLoadingState(_ notification: Notification) {
        NSLog("📱 Payment loading state changed")
        NSLog("📱 Loading state count: \(loadingStateCount)")
        
        if let isLoading = notification.userInfo?["isLoading"] as? Bool {
            NSLog("📱 Is Loading: \(isLoading)")
        }
        
        loadingStateCount += 1
        
        // If loading state persists for too long, trigger timeout
        if loadingStateCount > 3 {
            NSLog("❌ Loading state count exceeded limit (\(loadingStateCount))")
            handleLoadingTimeout()
            return
        }
        
        // Start loading state timer
        loadingStateTimer?.invalidate()
        loadingStateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            NSLog("⏰ Loading state timer triggered")
            self?.handleLoadingTimeout()
        }
    }
    
    @objc private func handleLoadingTimeout() {
        NSLog("❌ Payment loading state timeout")
        NSLog("📱 Final loading state count: \(loadingStateCount)")
        loadingStateTimer?.invalidate()
        paymentTimer?.invalidate()
        
        if let flutterVC = viewController as? FlutterViewController {
            flutterVC.dismiss(animated: true) {
                NSLog("📱 Dismissed payment screen due to loading timeout")
                let error = FlutterError(
                    code: "LOADING_TIMEOUT",
                    message: "Payment screen loading timed out after \(self.loadingStateCount) attempts. Please try again.",
                    details: nil
                )
                self.pendingResult?(error)
                self.pendingResult = nil
            }
        }
    }
    
    @objc private func handlePaymentTimeout() {
        NSLog("❌ Payment timeout reached")
        loadingStateTimer?.invalidate()
        paymentTimer?.invalidate()
        loadingStateCount = 0
        
        if let flutterVC = viewController as? FlutterViewController {
            flutterVC.dismiss(animated: true) {
                NSLog("📱 Dismissed payment screen due to payment timeout")
                let error = FlutterError(
                    code: "PAYMENT_TIMEOUT",
                    message: "Payment process timed out after 5 minutes. Please try again.",
                    details: nil
                )
                self.pendingResult?(error)
                self.pendingResult = nil
            }
        }
    }
    
    @objc private func handleSdkResponse(_ notification: Notification) {
        NSLog("📱 Received SDK response notification: \(notification.name)")
        NSLog("📱 Full notification: \(notification)")
        NSLog("📱 Notification object: \(String(describing: notification.object))")
        NSLog("📱 Notification userInfo: \(String(describing: notification.userInfo))")
        
        // Stop all timers
        paymentTimer?.invalidate()
        loadingStateTimer?.invalidate()
        loadingStateCount = 0
        
        if notification.userInfo == nil {
            NSLog("❌ No userInfo in notification")
            pendingResult?(FlutterError(
                code: "NO_RESPONSE",
                message: "No response data from payment SDK",
                details: nil
            ))
            pendingResult = nil
            return
        }
        
        // Log all userInfo keys and values for debugging
        if let userInfo = notification.userInfo {
            NSLog("📱 Payment response details:")
            for (key, value) in userInfo {
                NSLog("   \(key): \(value)")
            }
        }
        
        let isSuccessful = notification.userInfo?["isSuccessful"] as? Bool ?? false
        NSLog("📱 Payment isSuccessful: \(isSuccessful)")
        
        if isSuccessful {
            let reference = notification.userInfo?["paymentReference"] as? String ?? ""
            let cardID = notification.userInfo?["cardID"] as? String ?? ""
            
            NSLog("✅ Payment successful - Reference: \(reference), CardID: \(cardID)")
            
            pendingResult?([
                "success": true,
                "paymentReference": reference,
                "cardID": cardID
            ])
        } else {
            let errorCode = notification.userInfo?["errorCode"] as? Int ?? -1
            let errorMessage = notification.userInfo?["errorMessage"] as? String ?? "Unknown error"
            
            NSLog("❌ Payment failed with error code \(errorCode): \(errorMessage)")
            
            pendingResult?(FlutterError(
                code: String(errorCode),
                message: errorMessage,
                details: nil
            ))
        }
        
        pendingResult = nil
        NSLog("📱 Cleared pending result")
    }
    
    @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        pendingResult = result
        loadingStateCount = 0
        
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Arguments are required",
                               details: nil))
            return
        }
        
        // Add observers for all relevant notifications
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleSdkResponse),
                                             name: NSNotification.Name(kPaymentNotification),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleLoadingState),
                                             name: NSNotification.Name(kLoadingNotification),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handlePaymentError),
                                             name: NSNotification.Name(kErrorNotification),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handlePaymentTimeout),
                                             name: NSNotification.Name(kTimeoutNotification),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handlePaymentCancelled),
                                             name: NSNotification.Name(kCancelledNotification),
                                             object: nil)
        
        // Start payment timeout timer
        paymentTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: false) { [weak self] _ in
            self?.handlePaymentTimeout()
        }
        
        NSLog("📱 Received initializePayment call with arguments: \(String(describing: call.arguments))")
        
        guard let invoiceId = args["invoiceId"] as? String,
              let amount = args["amount"] as? Int,
              let postLink = args["postLink"] as? String,
              let failurePostLink = args["failurePostLink"] as? String,
              let backLink = args["backLink"] as? String,
              let failureBackLink = args["failureBackLink"] as? String,
              let description = args["description"] as? String,
              let terminal = args["terminal"] as? String,
              let auth = args["auth"] as? [String: Any],
              let accessToken = auth["access_token"] as? String
        else {
            let error = "Missing required parameters"
            NSLog("❌ \(error)")
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: error,
                              details: nil))
            return
        }
        
        // Check environment based on multiple indicators
        let isStaging = postLink.contains("stage-payment") || 
                       postLink.contains("test") || 
                       postLink.contains("dev") ||
                       failurePostLink.contains("stage-payment") ||
                       failurePostLink.contains("test") ||
                       failurePostLink.contains("dev")
        
        NSLog("📱 Environment detection:")
        NSLog("   Post Link: \(postLink)")
        NSLog("   Failure Post Link: \(failurePostLink)")
        NSLog("   Using \(isStaging ? "STAGING" : "PRODUCTION") environment")
        
        NSLog("📱 Payment configuration:")
        NSLog("   Invoice ID: \(invoiceId)")
        NSLog("   Amount: \(amount)")
        NSLog("   Terminal: \(terminal)")
        NSLog("   Post Link: \(postLink)")
        NSLog("   Back Link: \(backLink)")
        NSLog("   Description: \(description)")
        NSLog("   Environment: \(isStaging ? "STAGING" : "PRODUCTION")")
        NSLog("   Auth Token: \(String(accessToken.prefix(10)))...")
        
        let authConfig = AuthConfig(
            merchantId: terminal,
            merchantName: "Aina",
            clientId: terminal,
            clientSecret: accessToken
        )
        
        let invoice = Invoice(
            id: invoiceId,
            amount: Double(amount),
            currency: "KZT",
            accountId: args["accountId"] as? String ?? "1",
            description: description,
            postLink: postLink,
            backLink: backLink,
            failurePostLink: failurePostLink,
            failureBackLink: failureBackLink,
            isRecurrent: false,
            autoPaymentFrequency: .monthly
        )
        
        let pm = PaymentModel(authConfig: authConfig, invoice: invoice)
        
        DispatchQueue.main.async {
            let vc = LaunchScreenViewController(paymentModel: pm)
            vc.setEnvironmetType(type: isStaging ? .dev : .prod)
            
            if let flutterVC = self.viewController as? FlutterViewController {
                flutterVC.present(vc, animated: true) {
                    NSLog("📱 Presented payment screen")
                    NotificationCenter.default.post(
                        name: NSNotification.Name(self.kLoadingNotification),
                        object: nil,
                        userInfo: ["isLoading": true]
                    )
                }
            } else {
                let error = "Could not present payment screen"
                NSLog("❌ \(error)")
                result(FlutterError(code: "PRESENTATION_ERROR",
                                  message: error,
                                  details: nil))
            }
        }
    }
    
    @objc private func handlePaymentError(_ notification: Notification) {
        NSLog("❌ Payment error notification received")
        NSLog("📱 Full notification: \(notification)")
        
        loadingStateTimer?.invalidate()
        paymentTimer?.invalidate()
        loadingStateCount = 0
        
        let errorMessage = notification.userInfo?["errorMessage"] as? String ?? "Unknown error"
        let errorCode = notification.userInfo?["errorCode"] as? Int ?? -1
        
        if let flutterVC = viewController as? FlutterViewController {
            flutterVC.dismiss(animated: true) {
                NSLog("📱 Dismissed payment screen due to error")
                let error = FlutterError(
                    code: String(errorCode),
                    message: errorMessage,
                    details: nil
                )
                self.pendingResult?(error)
                self.pendingResult = nil
            }
        }
    }
    
    @objc private func handlePaymentCancelled(_ notification: Notification) {
        NSLog("📱 Payment cancelled by user")
        NSLog("📱 Full notification: \(notification)")
        
        loadingStateTimer?.invalidate()
        paymentTimer?.invalidate()
        loadingStateCount = 0
        
        if let flutterVC = viewController as? FlutterViewController {
            flutterVC.dismiss(animated: true) {
                NSLog("📱 Dismissed payment screen due to cancellation")
                let error = FlutterError(
                    code: "CANCELLED",
                    message: "Payment cancelled by user",
                    details: nil
                )
                self.pendingResult?(error)
                self.pendingResult = nil
            }
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let epayChannel = FlutterMethodChannel(
      name: "kz.aina/epay",
      binaryMessenger: controller.binaryMessenger
    )
    
    // Create and register the plugin
    let plugin = EpayPlugin(viewController: controller)
    epayChannel.setMethodCallHandler(plugin.handle)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
