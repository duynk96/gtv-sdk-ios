import UIKit

public enum WarningButtonState {
    case normal
    case full
}

public class WarningButton: UIButton {

    private var normalImage: UIImage?
    private var fullImage: UIImage?
    private var normalSize: CGSize
    private var fullSize: CGSize
    private(set) var currentState: WarningButtonState = .normal

    public init(
        normalImage: UIImage?,
        fullImage: UIImage?,
        normalSize: CGSize,
        fullSize: CGSize,
        origin: CGPoint
    ) {
        self.normalImage = normalImage
        self.fullImage = fullImage
        self.normalSize = normalSize
        self.fullSize = fullSize
        let frame = CGRect(origin: origin, size: normalSize)
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        self.normalSize = CGSize(width: 60, height: 60)
        self.fullSize = CGSize(width: 120, height: 120)
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
        self.updateState(.normal, animated: false)
    }

    /// Toggle trạng thái khi bấm
    @objc private func toggleState() {
        let nextState: WarningButtonState = currentState == .normal ? .full : .normal
        self.updateState(nextState, animated: true)
    }

    /// Cập nhật trạng thái với optional animation
    public func updateState(_ state: WarningButtonState, animated: Bool = false) {
        self.currentState = state
        let newImage = (state == .normal) ? normalImage : fullImage
        let newSize = (state == .normal) ? normalSize : fullSize

        let applyChanges = {
            self.setImage(newImage, for: .normal)
            self.bounds.size = newSize
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: applyChanges)
        } else {
            applyChanges()
        }
    }

    /// Update vị trí mà không thay đổi kích thước
    public func updatePosition(_ origin: CGPoint) {
        self.frame.origin = origin
    }
}

