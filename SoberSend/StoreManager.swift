import Foundation
import StoreKit

@MainActor
@Observable
class StoreManager {
    var isPremium: Bool = false
    var products: [Product] = []
    
    private let productIDs = ["com.sobersend.premium.monthly", "com.sobersend.premium.yearly"]
    private var updatesTask: Task<Void, Never>? = nil

    init() {
        Task {
            await requestProducts()
            await updatePremiumStatus()
        }
        updatesTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePremiumStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }

    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePremiumStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func updatePremiumStatus() async {
        var hasActiveSubscription = false

        // Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                }
            } catch {
                print("Transaction failed verification")
            }
        }

        isPremium = hasActiveSubscription
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePremiumStatus()
    }



    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
