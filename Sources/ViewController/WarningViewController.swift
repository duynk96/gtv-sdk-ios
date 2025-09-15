import UIKit

public class WarningViewController: UIViewController {


    private let warningButton: UIButton = {
        let size: CGFloat = 50
        let button = UIButton(type: .custom)
        if let image = UIImage(named: "splash_logo") {
            button.setImage(image, for: .normal)
        }        // button.setTitle("18+", for: .normal)
        // button.setTitleColor(.white, for: .normal)
        // button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        // button.backgroundColor = .red
        button.layer.cornerRadius = size / 2
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(warningButton)

        NSLayoutConstraint.activate([
            warningButton.widthAnchor.constraint(equalToConstant: 50),
            warningButton.heightAnchor.constraint(equalToConstant: 50),
            warningButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            warningButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        warningButton.addTarget(self, action: #selector(showWarningPopup), for: .touchUpInside)
    }

    @objc private func showWarningPopup() {
        // Overlay full screen
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Popup container
        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 12
        popup.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Nội dung chỉ dành cho người từ 18 tuổi trở lên."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Đóng", for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissOverlay(_:)), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        popup.addSubview(label)
        popup.addSubview(closeBtn)
        overlay.addSubview(popup)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 280),

            label.topAnchor.constraint(equalTo: popup.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -16),

            closeBtn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            closeBtn.bottomAnchor.constraint(equalTo: popup.bottomAnchor, constant: -20),
            closeBtn.centerXAnchor.constraint(equalTo: popup.centerXAnchor)
        ])

        overlay.alpha = 0
        UIView.animate(withDuration: 0.25) {
            overlay.alpha = 1
        }
    }

    @objc private func dismissOverlay(_ sender: UIButton) {
        sender.superview?.superview?.removeFromSuperview()
    }


    @objc private func dismissPopup(_ sender: UIButton) {
        sender.superview?.removeFromSuperview()
    }
}


