import UIKit

class SplashViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        if let image = UIImage(named: "ic_sdk_splash", in: .gtvSdk, compatibleWith: nil) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            let imageWidth: CGFloat = 100
            let imageHeight: CGFloat = 100
            imageView.frame = CGRect(
                x: (view.bounds.width - imageWidth)/2,
                y: (view.bounds.height - imageHeight)/2,
                width: imageWidth,
                height: imageHeight
            )
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                                          .flexibleTopMargin, .flexibleBottomMargin]
            view.addSubview(imageView)
        }
        
        GTVSdk.shared.requestNotificationPermission { granted in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               self.openLogin()
           }
        }
    }

    private func openLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
}
