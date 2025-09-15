import UIKit

public protocol GTVSdkListener: AnyObject {
    func onEventReceived(event: String, data: Any?)
}

public enum GTVEvents {
    public static let LOGIN_SUCCESS = "GTVLoginSuccess"
}

public class GTVSdk {
    public static let shared = GTVSdk()
    public let urlString = "https://accounts.gplaydev.com"
    
    private init() {}
    
    private weak var listener: GTVSdkListener?
    
    public func initSdk(clientId: String, adjustToken: String, isDebug: Bool, admobID: String) {
        SessionManager.shared.saveClientId(clientId)
    }
    
    public func setListener(_ listener: GTVSdkListener) {
        self.listener = listener
    }
    
    func dispatchEvent(event: String, data: Any?) {
        listener?.onEventReceived(event: event, data: data)
    }
    
    public func showSplash(from hostVC: UIViewController) {
        let splashVC = SplashViewController()
        let nav = UINavigationController(rootViewController: splashVC)
        nav.modalPresentationStyle = .fullScreen
        hostVC.present(nav, animated: true, completion: nil)
    }
    
    
    
    public func getTokenApp() -> String? {
        return SessionManager.shared.getToken()
    }
    
    public func getUserInfo(completion: @escaping ([String: Any]?) -> Void) {
        guard let token = SessionManager.shared.getToken(), !token.isEmpty else {
            completion(nil)
            return
        }
        
        let fields = ["avatar", "frame", "gender", "username", "address", "dob"]
        let fieldsString = fields.joined(separator: ",")
        let urlString = "https://accounts.gplaydev.com/auth-connect/api/v2.0/oauth2/auth/userinfo?fields=\(fieldsString)"
        
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SessionManager.shared.getClientId(), forHTTPHeaderField: "ClientID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                completion(json)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    public func requestNotificationPermission(callback: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Chưa yêu cầu quyền, yêu cầu user
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        callback(granted)
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    callback(true)
                }
            case .denied:
                DispatchQueue.main.async {
                    callback(false)
                }
            @unknown default:
                DispatchQueue.main.async {
                    callback(false)
                }
            }
        }
    }
    
    public func attachWarning18Plus(to parent: UIViewController) {
            let warningVC = WarningViewController()
            warningVC.view.frame = parent.view.bounds
            warningVC.view.backgroundColor = .clear

            parent.addChild(warningVC)
            parent.view.addSubview(warningVC.view)
            warningVC.didMove(toParent: parent)
        }
}
