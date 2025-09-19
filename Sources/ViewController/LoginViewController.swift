import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    // MARK: - Views
    private var webView: WKWebView!
    private var loadingView: LoadingView!
    private var backButton: UIButton!
    
    private var webViewTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        isModalInPresentation = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupLoadingView()
        setupBackButton()
        loadWebViewIfNeeded()
    }

    // MARK: - Setup LoadingView
    private func setupLoadingView() {
        loadingView = LoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Setup Back Button
    private func setupBackButton() {
        backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.tintColor = .black
        backButton.isHidden = true
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        backButton.layer.cornerRadius = 8
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOpacity = 0.2
        backButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        backButton.layer.shadowRadius = 2

        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 60),
            backButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func didTapBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    // MARK: - Load WebView
    private func loadWebViewIfNeeded() {
        if SessionManager.shared.getStatus() == Status.logout {
            clearWebViewCacheAndReload()
            return
        }
        let token = GTVSdk.shared.getTokenApp()
        if !token.isEmpty {
            GTVSdk.shared.getUserInfo { [weak self] userInfo in
                DispatchQueue.main.async {
                    if let info = userInfo {
                        print("✅ User info from SDK: \(info)")
                        GTVSdk.shared.dispatchEvent(event: GTVEvents.LOGIN_SUCCESS, data: nil)
                        self?.dismiss(animated: true)
                    } else {
                        self?.loadWebView()
                    }
                }
            }
        } else {
            loadWebView()
        }
    }

    private func loadWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "GTVLoginSuccess")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        view.bringSubviewToFront(loadingView)
        view.bringSubviewToFront(backButton)

        // Layout WebView
        webViewTopConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)
        webViewTopConstraint.isActive = true
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let url = URL(string: LoginViewController.getLoginUrl()) {
            loadingView.startAnimating()
            webView.load(URLRequest(url: url))
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // loadingView.startAnimating()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            if self.loadingView.isHidden == false {
                self.loadingView.stopAnimating()
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBackButtonVisibility()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {

    }

    // MARK: - Back button visibility
    private func updateBackButtonVisibility() {
        if webView.canGoBack {
            backButton.isHidden = false
            webViewTopConstraint.constant = 80 // height nút Back + margin
        } else {
            backButton.isHidden = true
            webViewTopConstraint.constant = 0
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
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

    // MARK: - Login URL
    static func getLoginUrl() -> String {
        let clientId = SessionManager.shared.getClientId()
        return """
        \(GTVSdk.shared.urlString)/auth-connect/api/v2.0/oauth2/auth?scope=account&response_type=token&response_mode=command&state=some_states&redirect_uri=https://default&access_type=offline&client_type=normal&os=ios&client_id=\(clientId)
        """
    }
    
    private func clearWebViewCacheAndReload() {
        let websiteDataTypes = Set([
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases,
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache
        ])
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes,
                                                modifiedSince: Date(timeIntervalSince1970: 0)) { [weak self] in
            print("🧹 WebView cache cleared")
            DispatchQueue.main.async {
                self?.loadWebView()
            }
        }
    }

}

// MARK: - LoadingView
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
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
        self.isHidden = false
        progressView.setProgress(0, animated: false)
        UIView.animate(withDuration: 5.0) {
            self.progressView.setProgress(1.0, animated: true)
        }
    }

    func stopAnimating() {
        self.isHidden = true
        self.progressView.layer.removeAllAnimations()
    }
}

