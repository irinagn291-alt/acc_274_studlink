import UIKit
import Alamofire
import OneSignalFramework

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.studlink.proof"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        OneSignal.initialize("ceec3ccb-2498-4991-863f-07ded47a6eb3", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ @Sendable _ in }, fallbackToSettings: false)
        application.registerForRemoteNotifications()
        return true
    }
}
