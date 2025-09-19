import UIKit

class FloatingButton: UIButton {
    
    private var popupView: UIView?
    private var initialTouchPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.backgroundColor = .systemBlue
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
        self.setImage(UIImage(named: "ic_sdk_float", in: .gtvSdk, compatibleWith: nil), for: .normal)
        
        // Bấm để show popup
        self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Gesture kéo thả
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
    }
    
    @objc private func buttonTapped() {
        if popupView == nil {
            showPopup()
        } else {
            hidePopup()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let touchPoint = gesture.location(in: superview)

        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            let dx = touchPoint.x - initialTouchPoint.x
            let dy = touchPoint.y - initialTouchPoint.y

            var newCenter = CGPoint(x: self.center.x + dx, y: self.center.y + dy)

            // Giới hạn button không vượt màn hình
            let halfWidth = self.bounds.width / 2
            let halfHeight = self.bounds.height / 2
            newCenter.x = max(halfWidth, min(superview.bounds.width - halfWidth, newCenter.x))
            newCenter.y = max(halfHeight, min(superview.bounds.height - halfHeight, newCenter.y))

            self.center = newCenter
            initialTouchPoint = touchPoint
        default:
            break
        }
    }
    
    @objc private func logoutTapped() {
        // Gọi SDK logout
        GTVSdk.shared.logout()
        hidePopup()
    }
    
    private func showPopup() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let popupHeight: CGFloat = 300
        let popup = UIView(frame: CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: popupHeight))
        popup.backgroundColor = .gray
        popup.layer.cornerRadius = 16
        window.addSubview(popup)
        self.popupView = popup
        
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.frame = CGRect(x: 20, y: 20, width: popup.frame.width - 40, height: 50)
        logoutButton.backgroundColor = .red
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.layer.cornerRadius = 8
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        popup.addSubview(logoutButton)
        
        UIView.animate(withDuration: 0.3) {
            popup.frame.origin.y = window.frame.height - popupHeight
        }
    }
    
    private func hidePopup() {
        guard let popup = popupView else { return }
        UIView.animate(withDuration: 0.3, animations: {
            popup.frame.origin.y += popup.frame.height
        }, completion: { _ in
            popup.removeFromSuperview()
        })
        popupView = nil
    }
}
