import Foundation
import StoreKit
import os.log

/// StoreManager handles all StoreKit 2 operations including product fetching,
/// purchase flow, transaction verification, and entitlement checking.
///
/// It uses the @Observable macro so SwiftUI views can observe changes to
/// `isPremium`, `products`, etc.
@MainActor
@Observable
class StoreManager {
    var isPremium: Bool = false
    var products: [Product] = []
    /// Controls whether the paywall shows a loading indicator while fetching
    /// products from the App Store.
    var isLoadingProducts: Bool = false
    /// Holds an error message if `requestProducts()` fails.  When non-nil the
    /// paywall should surface the message to the user.
    var productsLoadError: String? = nil

    /// The two product identifiers registered in App Store Connect.
    private let productIDs = [
        "com.sobersend.premium.monthly",
        "com.sobersend.premium.yearly"
    ]

    // MARK: - Init

    init() {
        Task {
            await requestProducts()
            await refreshPremiumStatus()
        }
        Task {
            await observeTransactionUpdates()
        }
    }

    // MARK: - Products

    /// Fetches the list of available products from the App Store.
    /// Sets `products` on success, or `productsLoadError` on failure.
    func requestProducts() async {
        isLoadingProducts = true
        productsLoadError = nil
        os_log("[StoreManager] requesting products for IDs: %{public}@", log: .default, type: .debug, productIDs)

        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted { $0.price < $1.price }
            os_log("[StoreManager] loaded %{public}d products", log: .default, type: .debug, products.count)

            if products.isEmpty {
                productsLoadError = "No products found. Make sure your StoreKit configuration is selected in the scheme."
                os_log("[StoreManager] Product.products returned empty – check scheme StoreKit config", log: .default, type: .error)
            }
        } catch {
            productsLoadError = error.localizedDescription
            os_log("[StoreManager] Product request failed: %{public}@", log: .default, type: .error, error.localizedDescription)
        }

        isLoadingProducts = false
    }

    // MARK: - Purchasing

    /// Initiates a purchase for the given `Product`.
    /// After a successful purchase this method refreshes the premium status
    /// via `refreshPremiumStatus()`.
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            os_log("[StoreManager] purchase succeeded, refreshing entitlement", log: .default, type: .info)
            await refreshPremiumStatus()
            await transaction.finish()
        case .userCancelled:
            os_log("[StoreManager] user cancelled purchase", log: .default, type: .info)
        case .pending:
            os_log("[StoreManager] purchase is pending", log: .default, type: .info)
        @unknown default:
            os_log("[StoreManager] unknown purchase result", log: .default, type: .error)
        }
    }

    // MARK: - Entitlements

    /// Reads the current entitlements from StoreKit and updates `isPremium`.
    /// Call this after a purchase or on app launch.
    func refreshPremiumStatus() async {
        os_log("[StoreManager] refreshing premium status...", log: .default, type: .debug)
        var foundActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // Only count auto-renewable subscriptions
                if transaction.productType == .autoRenewable {
                    foundActiveSubscription = true
                    os_log("[StoreManager] active subscription found: %{public}@", log: .default, type: .info, transaction.productID)
                }
            } catch {
                os_log("[StoreManager] entitlement verification failed: %{public}@", log: .default, type: .error, error.localizedDescription)
            }
        }

        isPremium = foundActiveSubscription
        os_log("[StoreManager] premium status: %{public}s", log: .default, type: .info, isPremium ? "PREMIUM" : "NOT PREMIUM")
    }

    /// Restores purchases by syncing with the App Store and then refreshing
    /// the local entitlement cache.
    func restorePurchases() async {
        os_log("[StoreManager] restoring purchases...", log: .default, type: .info)
        do {
            try await AppStore.sync()
            os_log("[StoreManager] AppStore.sync() completed", log: .default, type: .info)
        } catch {
            os_log("[StoreManager] AppStore.sync() failed: %{public}@", log: .default, type: .error, error.localizedDescription)
        }
        await refreshPremiumStatus()
    }

    // MARK: - Transaction Observation

    /// Listens for new transactions (e.g. renewals, restores) and updates the
    /// premium status accordingly.
    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                os_log("[StoreManager] transaction update received: %{public}@", log: .default, type: .info, transaction.productID)
                await refreshPremiumStatus()
                await transaction.finish()
            } catch {
                os_log("[StoreManager] transaction update failed verification: %{public}@", log: .default, type: .error, error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    /// Verifies a StoreKit 2 `VerificationResult<T>`.
    /// On success returns the verified payload.  On failure throws
    /// `StoreError.failedVerification`.
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

// MARK: - Errors

enum StoreError: Error, Equatable, LocalizedError {
    case failedVerification
    case userNotAuthorized

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "We couldn't verify your purchase with Apple. Please try again or restore your purchases."
        case .userNotAuthorized:
            return "Please sign in with your Apple ID and try again."
        }
    }
}
