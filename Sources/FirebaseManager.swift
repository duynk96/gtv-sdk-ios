import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    private override init() {}
    
    // MARK: - Init Firebase
    func initFirebase() {
        guard FirebaseApp.app() == nil else {
            print("⚠️ Firebase already configured")
            return
        }
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            print("✅ Firebase configured with host app GoogleService-Info.plist")
        }
        else if let sdkBundle = Bundle(for: FirebaseManager.self).path(forResource: "GoogleService-Info", ofType: "plist"),
                let options = FirebaseOptions(contentsOfFile: sdkBundle) {
            FirebaseApp.configure(options: options)
            print("✅ Firebase configured with SDK bundle GoogleService-Info.plist")
        }
        else {
            print("❌ GoogleService-Info.plist not found in host app bundle or SDK bundle")
        }
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()
    }
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func subscribeTopic(_ topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("❌ Failed to subscribe to topic \(topic): \(error.localizedDescription)")
            } else {
                print("✅ Subscribed to topic: \(topic)")
            }
        }
    }
    
    func unsubscribeTopic(_ topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("❌ Failed to unsubscribe from topic \(topic): \(error.localizedDescription)")
            } else {
                print("✅ Unsubscribed from topic: \(topic)")
            }
        }
    }
}


// MARK: - MessagingDelegate
extension FirebaseManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        let clientId = SessionManager.shared.getClientId()
        self.subscribeTopic("games-\(clientId)")
        // GTVSdk.shared.dispatchEvent(event: GTVEvents.FCM_TOKEN, data: token)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📩 Foreground notification: \(userInfo)")

        // GTVSdk.shared.dispatchEvent(event: GTVEvents.NOTIFICATION_RECEIVED, data: userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 Notification tapped: \(userInfo)")

        // GTVSdk.shared.dispatchEvent(event: GTVEvents.NOTIFICATION_OPENED, data: userInfo)
        completionHandler()
    }
}
