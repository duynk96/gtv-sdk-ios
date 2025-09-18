import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var loadingView: LoadingView! 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        isModalInPresentation = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupLoadingView()
        
        let token = GTVSdk.shared.getTokenApp()
        
        if !token.isEmpty {
            GTVSdk.shared.getUserInfo { userInfo in
                DispatchQueue.main.async {
                    if let info = userInfo {
                        print("✅ User info from SDK: \(info)")
                        
                        GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: nil)
                        
                        self.dismiss(animated: true)
                    } else {
                        self.loadWebView()
                    }
                }
            }
        } else {
            loadWebView()
        }
    }
    
    private func setupLoadingView() {
        loadingView = LoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func loadWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "GTVLoginSuccess")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "MyApp/1.0 (iOS)"
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        view.bringSubviewToFront(loadingView)

        if let url = URL(string: LoginViewController.getLoginUrl()) {
            webView.load(URLRequest(url: url))
            loadingView.startAnimating()
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingView.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingView.stopAnimating()
        self.loadingView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingView.stopAnimating()
        self.loadingView.isHidden = true
    }
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "GTVLoginSuccess" {
            if let data = message.body as? [String: Any], let token = data["data"] as? String {
                SessionManager.shared.saveToken(token: token)
                GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: nil)
                
                self.dismiss(animated: true)
            }
        }
    }

    static func getLoginUrl() -> String {
        let clientId = SessionManager.shared.getClientId()
        return """
        \(GTVSdk.shared.urlString)/auth-connect/api/v2.0/oauth2/auth?scope=account&response_type=token&response_mode=command&state=some_states&redirect_uri=https://default&access_type=offline&client_type=normal&os=ios&client_id=\(clientId)
        """
    }
}


class LoadingView: UIView {
    private let iconView: UIImageView = {
        let img = UIImageView(image: UIImage(named: "ic_sdk_splash", in: .gtvSdk, compatibleWith: nil))
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFit
        
        return img
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        pv.progressTintColor = UIColor.red
        pv.layer.cornerRadius = 4
        pv.clipsToBounds = true
        return pv
    }()
    
    private var timer: Timer?
    private var direction: Float = 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        startAnimating()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        startAnimating()
    }
    
    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [iconView, progressView])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            iconView.widthAnchor.constraint(equalToConstant: 100),
            iconView.heightAnchor.constraint(equalToConstant: 100),
            
            progressView.widthAnchor.constraint(equalToConstant: 120),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    func startAnimating() {
        progressView.setProgress(0, animated: false)
        
        UIView.animate(withDuration: 5.0) {
            self.progressView.setProgress(1.0, animated: true)
        }
    }
    
    func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
}
