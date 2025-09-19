import GoogleMobileAds
import UIKit

internal class AdmobManager: NSObject {
    static let shared = AdmobManager()
    private override init() {}

    private let MAX_QUEUE = 2
    private var adUnitId: String?
    private var adQueue: [RewardedAd] = []

    // MARK: - Init
    func initAdmob(admobID: String) {
        adUnitId = admobID

        MobileAds.shared.start { status in
            print("✅ Google Mobile Ads initialized: \(status.adapterStatusesByClassName)")
        }


        loadAd()
    }

    // MARK: - Load Ad
    private func loadAd() {
        guard let id = adUnitId else { return }
        if adQueue.count >= MAX_QUEUE { return }

        let request = Request()
        RewardedAd.load(with: id, request: request) { [weak self] ad, error in
            if let error = error {
                GTVSdk.shared.dispatchEvent(event: GTVEvents.AD_FAILED, data: error.localizedDescription)
                return
            }
            if let ad = ad {
                self?.adQueue.append(ad)
                GTVSdk.shared.dispatchEvent(event: GTVEvents.AD_LOADED, data: nil)
            }
        }

    }

    func showRewarded(from viewController: UIViewController) {
        guard let ad = adQueue.first else {
            loadAd()
            GTVSdk.shared.dispatchEvent(event: GTVEvents.AD_FAILED, data: "No Ad available")
            return
        }
        
        ad.fullScreenContentDelegate = self
        adQueue.removeFirst()
        
        ad.present(from: viewController) {
            let reward = ad.adReward
            GTVSdk.shared.dispatchEvent(
                event: GTVEvents.REWARD_EARNED,
                data: ["type": reward.type, "amount": reward.amount]
            )
            self.loadAd()
        }
    }

}

// MARK: - GADFullScreenContentDelegate
extension AdmobManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        GTVSdk.shared.dispatchEvent(event: GTVEvents.AD_CLOSED, data: nil)
        loadAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        GTVSdk.shared.dispatchEvent(event: GTVEvents.AD_FAILED, data: error.localizedDescription)
        loadAd()
    }
}
