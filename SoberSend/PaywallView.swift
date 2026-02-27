import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    /// When set, renders a "Continue with Free" button inside the scroll content.
    var onContinueWithFree: (() -> Void)? = nil

    @State private var selectedProductID: String? = nil
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String? = nil
    @State private var didPurchase = false
    @State private var shieldGlow = false

    private let monthlyID = "com.sobersend.premium.monthly"
    private let yearlyID = "com.sobersend.premium.yearly"

    private var monthlyProduct: Product? {
        storeManager.products.first { $0.id == monthlyID }
    }
    private var yearlyProduct: Product? {
        storeManager.products.first { $0.id == yearlyID }
    }
    private var selectedProduct: Product? {
        guard let id = selectedProductID else { return yearlyProduct }
        return storeManager.products.first { $0.id == id }
    }

    private var yearlyHasTrial: Bool {
        yearlyProduct?.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    private func yearlyPerMonth(_ product: Product) -> String {
        let perMonth = product.price / 12
        return product.priceFormatStyle.format(perMonth) + "/mo"
    }

    private var ctaLabel: String {
        guard let product = selectedProduct else { return "Subscribe" }
        if product.id == yearlyID, yearlyHasTrial {
            return "Start Free Trial"
        }
        let period = product.subscription?.subscriptionPeriod.unit == .month ? "Monthly" : "Yearly"
        return "Start \(period) Plan"
    }

    var body: some View {
        ZStack {
            backgroundView

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    if onContinueWithFree == nil {
                        closeButton
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    } else {
                        Spacer().frame(height: 24)
                    }

                    heroSection
                        .padding(.top, 12)

                    if yearlyHasTrial {
                        trialBadge
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                    }

                    featuresSection
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    planSelector
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    ctaButton
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    footerSection

                    if let continueAction = onContinueWithFree {
                        Button("Continue with Free") { continueAction() }
                            .font(SoberTheme.body())
                            .foregroundStyle(SoberTheme.textSecondary)
                            .padding(.top, 4)
                            .padding(.bottom, 52)
                    } else {
                        Spacer().frame(height: 44)
                    }
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            if didPurchase { successOverlay }
        }
        .background(SoberTheme.charcoal)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedProductID == nil { selectedProductID = yearlyID }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                shieldGlow = true
            }
        }
        .task {
            if storeManager.products.isEmpty && !storeManager.isLoadingProducts {
                await storeManager.requestProducts()
            }
            if selectedProductID == nil { selectedProductID = yearlyID }
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            SoberTheme.charcoal.ignoresSafeArea()
            
            // Soft lavender glow at top
            Circle()
                .fill(SoberTheme.lavender.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -180)
            
            // Subtle mint glow at bottom
            Circle()
                .fill(SoberTheme.mint.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Close Button
    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            .accessibilityLabel("Close")
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(SoberTheme.lavender.opacity(shieldGlow ? 0.25 : 0.1))
                    .frame(width: 130, height: 130)
                    .blur(radius: 10)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(SoberTheme.lavender)
            }

            VStack(spacing: 6) {
                Text("Unlock Full SoberSend")
                    .font(SoberTheme.title(28))
                    .foregroundStyle(.white)
                Text("Your complete sobriety shield, every night.")
                    .font(SoberTheme.body())
                    .foregroundStyle(SoberTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Trial Badge
    private var trialBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SoberTheme.mint)
            Text("7-day free trial included with the yearly plan — cancel anytime")
                .font(SoberTheme.caption())
                .fontWeight(.semibold)
                .foregroundStyle(SoberTheme.mint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(SoberTheme.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(SoberTheme.mint.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                FeatureCard(icon: "person.crop.circle.badge.plus", title: "Unlimited Contacts", subtitle: "Lock as many as you need", color: SoberTheme.lavender)
                FeatureCard(icon: "apps.iphone", title: "Unlimited Apps", subtitle: "Block your biggest triggers", color: SoberTheme.skyBlue)
            }
            HStack(spacing: 10) {
                FeatureCard(icon: "flame.fill", title: "Hard & Expert", subtitle: "Unlock all challenge levels", color: SoberTheme.peach)
                FeatureCard(icon: "chart.bar.fill", title: "Full Stats", subtitle: "Track progress over time", color: SoberTheme.mint)
            }
        }
    }

    // MARK: - Plan Selector
    private var planSelector: some View {
        VStack(spacing: 10) {
            if let yearly = yearlyProduct {
                PlanCard(
                    product: yearly,
                    badge: yearlyHasTrial ? "7-Day Free Trial" : "Best Value",
                    badgeColor: yearlyHasTrial ? SoberTheme.mint : SoberTheme.lavender,
                    subtitle: "Only \(yearlyPerMonth(yearly)) · billed $\(yearly.displayPrice)/yr",
                    isSelected: selectedProductID == yearlyID
                ) { selectedProductID = yearlyID }
            }
            if let monthly = monthlyProduct {
                PlanCard(
                    product: monthly,
                    badge: nil,
                    badgeColor: .clear,
                    subtitle: "Renews monthly",
                    isSelected: selectedProductID == monthlyID
                ) { selectedProductID = monthlyID }
            }
            if storeManager.isLoadingProducts {
                HStack(spacing: 10) {
                    ProgressView().tint(SoberTheme.lavender)
                    Text("Loading plans…")
                        .font(SoberTheme.body())
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if storeManager.products.isEmpty {
                VStack(spacing: 12) {
                    Text(storeManager.productsLoadError != nil
                         ? "Couldn't load plans."
                         : "No plans available.")
                        .font(SoberTheme.body())
                        .foregroundStyle(SoberTheme.textSecondary)
                    Button {
                        Task { await storeManager.requestProducts() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(SoberTheme.caption())
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(SoberTheme.lavender.opacity(0.3), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - CTA
    private var ctaButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await handlePurchase() }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(SoberTheme.charcoal)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: selectedProduct?.id == yearlyID && yearlyHasTrial ? "gift.fill" : "lock.open.fill")
                            Text(ctaLabel)
                                .font(SoberTheme.headline())
                        }
                        .foregroundStyle(SoberTheme.charcoal)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(SoberTheme.lavender, in: RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isPurchasing || isRestoring || selectedProduct == nil)
            .alert("Purchase Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }

            if selectedProduct?.id == yearlyID, yearlyHasTrial {
                Text("No charge today. Trial ends after 7 days.")
                    .font(SoberTheme.caption())
                    .foregroundStyle(SoberTheme.textSecondary)
            }
        }
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await handleRestore() }
            } label: {
                HStack(spacing: 6) {
                    if isRestoring { ProgressView().tint(SoberTheme.lavender).scaleEffect(0.8) }
                    Text("Restore Purchases")
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                        .underline()
                }
            }
            .disabled(isRestoring || isPurchasing)

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the period ends. Cancel anytime in your Apple ID settings.")
                .font(SoberTheme.caption(10))
                .foregroundStyle(SoberTheme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://musamasalla.github.io/SoberSend/privacy.html")!)
                Text("·").foregroundStyle(SoberTheme.textSecondary.opacity(0.4))
                Link("Terms of Service", destination: URL(string: "https://musamasalla.github.io/SoberSend/terms.html")!)
            }
            .font(SoberTheme.caption(10))
            .foregroundStyle(SoberTheme.textSecondary.opacity(0.6))
            .padding(.top, 4)
        }
        .padding(.top, 20)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            SoberTheme.charcoal.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(SoberTheme.mint.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(SoberTheme.mint)
                }
                
                Text("You're Premium! 🎉")
                    .font(SoberTheme.title(26))
                    .foregroundStyle(.white)
                Text("All features are now unlocked.\nStay strong tonight.")
                    .font(SoberTheme.body())
                    .foregroundStyle(SoberTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Let's Go →") { dismiss() }
                    .buttonStyle(SoberPrimaryButtonStyle(color: SoberTheme.lavender))
                    .frame(width: 200)
                    .padding(.top, 4)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Actions
    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await storeManager.purchase(product)
            if storeManager.isPremium {
                withAnimation(.spring(response: 0.4)) { didPurchase = true }
            }
        } catch StoreKitError.userCancelled {
            // Silently ignore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleRestore() async {
        isRestoring = true
        defer { isRestoring = false }
        await storeManager.restorePurchases()
        if storeManager.isPremium {
            withAnimation(.spring(response: 0.4)) { didPurchase = true }
        }
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SoberTheme.headline(13))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(SoberTheme.caption(11))
                    .foregroundStyle(SoberTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SoberTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(SoberTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let badge: String?
    let badgeColor: Color
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? SoberTheme.lavender : SoberTheme.border,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(SoberTheme.lavender)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(SoberTheme.headline(15))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(SoberTheme.caption(10))
                                .fontWeight(.bold)
                                .foregroundStyle(SoberTheme.charcoal)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(badgeColor, in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                }

                Spacer(minLength: 4)

                Text(product.displayPrice)
                    .font(SoberTheme.headline(16))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                isSelected ? SoberTheme.lavender.opacity(0.12) : SoberTheme.surface,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? SoberTheme.lavender.opacity(0.5) : SoberTheme.border,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
