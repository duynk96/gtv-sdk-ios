import Foundation

internal struct Status {
    static let login = "login"
    static let logout = "logout"
}

internal class SessionManager {
    static let shared = SessionManager()

    private let tokenKey = "gtv_token"
    private let clientIdKey = "gtv_client_id"
    private let packageNameKey = "gtv_package"
    private let statusKey = "gtv_status"
    
    
    func saveToken(token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(Status.login, forKey: statusKey)
    }

    func getToken() -> String {
        return UserDefaults.standard.string(forKey: tokenKey) ?? ""
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.set(Status.logout, forKey: statusKey)
    }

    func saveClientId(_ clientId: String) {
        UserDefaults.standard.set(clientId, forKey: clientIdKey)
    }

    func getClientId() -> String {
        return UserDefaults.standard.string(forKey: clientIdKey) ?? ""
    }
    
    func getStatus() -> String {
        return UserDefaults.standard.string(forKey: statusKey) ?? ""
    }}
