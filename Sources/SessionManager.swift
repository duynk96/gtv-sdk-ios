import Foundation

internal class SessionManager {
    static let shared = SessionManager()

    private let tokenKey = "gtv_token"
    private let clientIdKey = "gtv_client_id"
    private let packageNameKey = "gtv_package"

    func saveToken(token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    func saveClientId(_ clientId: String) {
        UserDefaults.standard.set(clientId, forKey: clientIdKey)
    }

    func getClientId() -> String {
        return UserDefaults.standard.string(forKey: clientIdKey) ?? ""
    }
}
