import Foundation
import StoreKit

@MainActor
@Observable
class StoreManager {
    var isPremium: Bool = false
    var products: [Product] = []
    // Exposed so the paywall can show a spinner vs an error + retry
    var isLoadingProducts: Bool = false
    var productsLoadError: String? = nil

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
        isLoadingProducts = true
        productsLoadError = nil
        print("🛒 StoreManager: requesting products for IDs: \(productIDs)")
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted { $0.price < $1.price }
            print("🛒 StoreManager: loaded \(products.count) products: \(products.map { "\($0.displayName) (\($0.id)) — \($0.displayPrice)" })")
            if products.isEmpty {
                productsLoadError = "No products found. Make sure your StoreKit configuration is selected in the scheme."
                print("⚠️ StoreManager: Product.products returned empty — check scheme StoreKit config")
            }
        } catch {
            productsLoadError = error.localizedDescription
            print("❌ StoreManager: Product request failed: \(error)")
        }
        isLoadingProducts = false
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
