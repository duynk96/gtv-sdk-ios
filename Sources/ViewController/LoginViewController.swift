import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        isModalInPresentation = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let token = SessionManager.shared.getToken(), !token.isEmpty {
            GTVSdk.shared.getUserInfo { userInfo in
                DispatchQueue.main.async {
                    if let info = userInfo {
                        print("✅ User info from SDK: \(info)")
                        
                        GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: info)
                        
                        self.dismiss(animated: true)
                    } else {
                        self.loadWebView()
                    }
                }
            }
        } else {
            // Chưa có token, load WebView để login
            loadWebView()
        }
    }
    
    private func loadWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "GTVLoginSuccess")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // Load login URL
        if let url = URL(string: LoginViewController.getLoginUrl()) {
            webView.load(URLRequest(url: url))
        }
    }
    
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "GTVLoginSuccess" {
            if let data = message.body as? [String: Any], let token = data["data"] as? String {
                SessionManager.shared.saveToken(token: token)
                // Dispatch event cho SDK
                GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: nil)
                // Dismiss WebView
                dismiss(animated: true)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url, url.absoluteString.contains("access_token=") {
            if let token = extractToken(from: url) {
                SessionManager.shared.saveToken(token: token)
                GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: token)
                dismiss(animated: true)
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func extractToken(from url: URL) -> String? {
        guard let fragment = url.fragment else { return nil }
        for param in fragment.split(separator: "&") {
            let kv = param.split(separator: "=")
            if kv.first == "access_token" {
                return String(kv.last ?? "")
            }
        }
        return nil
    }

    static func getLoginUrl() -> String {
        let clientId = SessionManager.shared.getClientId()
        return """
        \(GTVSdk.shared.urlString)/auth-connect/api/v2.0/oauth2/auth?scope=account&response_type=token&response_mode=command&state=some_states&redirect_uri=https://default&access_type=offline&client_type=lite&os=ios&client_id=\(clientId)
        """
    }
}
