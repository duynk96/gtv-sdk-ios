import Foundation
import StoreKit
import UIKit

internal class IAPManager {
    static let shared = IAPManager()
    
    private init() {}
    
    public var products: [Product] = []
    
    func queryProducts(identifiers: [String]) async {
        do {
            let storeProducts = try await Product.products(for: identifiers)
            self.products = storeProducts
            GTVSdk.shared.dispatchEvent(
                event: GTVEvents.BILLING_CONNECTED,
                data: storeProducts.map { ["id": $0.id, "price": $0.displayPrice] }
            )
        } catch {
            print("❌ Failed to fetch products: \(error)")
            GTVSdk.shared.dispatchEvent(
                event: GTVEvents.BILLING_ERROR,
                data: error.localizedDescription
            )
        }
    }
    
    func purchase(productId: String) async {
        guard let product = products.first(where: { $0.id == productId }) else {
            GTVSdk.shared.dispatchEvent(event: GTVEvents.BILLING_ERROR, data: "Product not found")
            return
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .unverified(_, let error):
                    print("⚠️ Unverified purchase: \(error.localizedDescription)")
                    GTVSdk.shared.dispatchEvent(
                        event: GTVEvents.BILLING_ERROR,
                        data: error.localizedDescription
                    )
                case .verified(let transaction):
                    await handleTransaction(transaction)
                }
            case .userCancelled:
                GTVSdk.shared.dispatchEvent(
                    event: GTVEvents.BILLING_ERROR,
                    data: "User canceled"
                )
            case .pending:
                GTVSdk.shared.dispatchEvent(
                    event: GTVEvents.BILLING_ERROR,
                    data: "Purchase pending"
                )
            @unknown default:
                break
            }
        } catch {
            print("❌ Purchase failed: \(error.localizedDescription)")
            GTVSdk.shared.dispatchEvent(
                event: GTVEvents.BILLING_ERROR,
                data: error.localizedDescription
            )
        }
    }
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                await handleTransaction(transaction, isRestore: true)
            case .unverified(_, let error):
                print("⚠️ Unverified restore: \(error.localizedDescription)")
                GTVSdk.shared.dispatchEvent(
                    event: GTVEvents.BILLING_ERROR,
                    data: error.localizedDescription
                )
            }
        }
    }
    
    // MARK: - Handle Transaction
    private func handleTransaction(_ transaction: Transaction, isRestore: Bool = false) async {
        let data: [String: Any] = [
            "productId": transaction.productID,
            "transactionId": transaction.id,
            "date": transaction.purchaseDate
        ]
        
        if isRestore {
            GTVSdk.shared.dispatchEvent(event: GTVEvents.PURCHASES_RESTORED, data: data)
        } else {
            GTVSdk.shared.dispatchEvent(event: GTVEvents.PURCHASE_UPDATED, data: data)
        }
        
        await transaction.finish()
    }
}
