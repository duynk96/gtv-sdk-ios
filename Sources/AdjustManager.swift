import AdjustSdk

internal class AdjustManager {
    static let shared = AdjustManager()
    private init() {}

    func initAdjust(appToken: String, env: String) {
        let environment: String
        switch env.lowercased() {
        case "sandbox":
            environment = ADJEnvironmentSandbox
        case "production":
            environment = ADJEnvironmentProduction
        default:
            environment = ADJEnvironmentProduction
        }
        
        guard let adjustConfig = ADJConfig(appToken: appToken,
                                           environment: environment) else {
            print("❌ Adjust init failed: invalid config")
            return
        }

        Adjust.initSdk(adjustConfig)
        print("✅ Adjust initialized with token=\(appToken), env=\(env)")
    }

    func trackEvent(
        token: String,
        parameters: [String: String]? = nil,
        amount: Double? = nil,
        currency: String? = nil
    ) {
        guard let event = ADJEvent(eventToken: token) else {
            print("❌ Adjust trackEvent failed: invalid event token")
            return
        }

        if let amount = amount, let currency = currency {
            event.setRevenue(amount, currency: currency)
            print("💰 Set revenue: \(amount) \(currency)")
        }

        parameters?.forEach { key, value in
            event.addCallbackParameter(key, value: value)
        }

        Adjust.trackEvent(event)
        print("📤 Adjust event tracked: token=\(token), params=\(parameters ?? [:])")
    }
}


