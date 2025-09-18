import UIKit

private class BundleFinder {}

extension Bundle {
    static var gtvSdk: Bundle = {
        // Bundle chứa resource bundle
        let bundle = Bundle(for: BundleFinder.self)

        // Tìm file GTVSdkResources.bundle
        if let url = bundle.url(forResource: "GTVSdkResources", withExtension: "bundle"),
           let resourceBundle = Bundle(url: url) {
            return resourceBundle
        }

        // Nếu không tìm thấy, fallback về main bundle (trường hợp debug)
        return bundle
    }()
}

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
    
    private var floatingButton: FloatingButton?
    private var warningButton: WarningButton?
    
    private weak var listener: GTVSdkListener?
    
    public func initSdk(clientId: String, adjustToken: String, isDebug: Bool, admobID: String) {
        SessionManager.shared.saveClientId(clientId)
        // FirebaseManager.shared.configure()
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
    
    public func getTokenApp() -> String {
        return SessionManager.shared.getToken()
    }
    
    public func getUserInfo(completion: @escaping ([String: Any]?) -> Void) {
        let token = getTokenApp()
        guard !token.isEmpty else {
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // Kiểm tra status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("HTTP error: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ JSON:", json)
                    completion(json)
                } else {
                    print("❌ JSON không đúng định dạng")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing error:", error)
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
    
    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    // Attach Floating Button
    public func showFloatingButton(size: CGFloat = 60) {
        guard let window = getKeyWindow() else { return }
        
        if floatingButton != nil { return }
        
        let button = FloatingButton(frame: CGRect(x: 100, y: 200, width: size, height: size))
       
        window.addSubview(button)
        floatingButton = button
    }

        /// Ẩn button
    public func hideFloatingButton() {
        floatingButton?.removeFromSuperview()
        floatingButton = nil
    }

    
    // Attach Warning Button
    public func showWarningButton(
            origin: CGPoint
        ) {
            guard let window = getKeyWindow() else { return }

            if warningButton == nil {
                let b = WarningButton(
                    normalImage: UIImage(named: "ic_sdk_warning", in: .gtvSdk, compatibleWith: nil),       fullImage: UIImage(named: "ic_sdk_warning_full", in: .gtvSdk, compatibleWith: nil),
                    normalSize: CGSize(width: 60, height: 60),
                    fullSize: CGSize(width: 150, height: 60),
                    origin: origin
                )
                window.addSubview(b)
                warningButton = b
            } else {
                warningButton?.updatePosition(origin)
                warningButton?.updateState(.normal)
            }
        }
    
    public func hideWarningButton() {
        warningButton?.removeFromSuperview()
        warningButton = nil
    }
}
