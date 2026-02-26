import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    /// When set, renders a "Continue with Free" button inside the scroll content.
    /// Used during onboarding so it stays above the TabView page indicator dots.
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

    // Detect if the yearly plan has a free trial introductory offer
    private var yearlyHasTrial: Bool {
        yearlyProduct?.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    // Per-month price string for yearly plan
    private func yearlyPerMonth(_ product: Product) -> String {
        let perMonth = product.price / 12
        return product.priceFormatStyle.format(perMonth) + "/mo"
    }

    // CTA label: shows "Start Free Trial" if trial available and yearly selected
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
                    // Safe area spacer + close button (hidden during onboarding — use "Continue with Free")
                    if onContinueWithFree == nil {
                        closeButton
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    } else {
                        Spacer().frame(height: 24)
                    }

                    heroSection
                        .padding(.top, 12)

                    // Trial notice badge
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

                    // "Continue with Free" rendered INSIDE the scroll so it's
                    // always visible above the TabView page-indicator dots.
                    if let continueAction = onContinueWithFree {
                        Button("Continue with Free") { continueAction() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 4)
                            .padding(.bottom, 52)
                    } else {
                        Spacer().frame(height: 44)
                    }
                }
                // iPad: constrain to a readable width
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            if didPurchase { successOverlay }
        }
        // Use safeAreaInset so we don't fight with the nav bar
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedProductID == nil { selectedProductID = yearlyID }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                shieldGlow = true
            }
        }
        .task {
            // requestProducts already called in StoreManager.init(), but retry if still empty.
            if storeManager.products.isEmpty && !storeManager.isLoadingProducts {
                await storeManager.requestProducts()
            }
            if selectedProductID == nil { selectedProductID = yearlyID }
        }
    }

    // MARK: - Background (near-black, subtle top glow)
    private var backgroundView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // Subtle top-center glow only
            Circle()
                .fill(Color(red: 0.40, green: 0.28, blue: 0.90).opacity(0.12))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -180)
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
                    .foregroundStyle(.white.opacity(0.35))
            }
            .accessibilityLabel("Close")
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.45, green: 0.32, blue: 0.95).opacity(shieldGlow ? 0.50 : 0.20),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 75
                        )
                    )
                    .frame(width: 150, height: 150)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: shieldGlow)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.80, green: 0.72, blue: 1.0), Color(red: 0.45, green: 0.32, blue: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.45, green: 0.32, blue: 0.95).opacity(0.55), radius: 22, y: 6)
            }

            VStack(spacing: 6) {
                Text("Unlock Full SoberSend")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Your complete sobriety shield, every night.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.60))
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
                .foregroundStyle(Color(red: 0.45, green: 0.95, blue: 0.65))
            Text("7-day free trial included with the yearly plan — cancel anytime")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.45, green: 0.95, blue: 0.65))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.45, green: 0.95, blue: 0.65).opacity(0.10), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(red: 0.45, green: 0.95, blue: 0.65).opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                FeatureCard(
                    icon: "person.crop.circle.badge.plus",
                    title: "Unlimited Contacts",
                    subtitle: "Lock as many as you need",
                    color: Color(red: 0.45, green: 0.32, blue: 0.95)
                )
                FeatureCard(
                    icon: "apps.iphone",
                    title: "Unlimited Apps",
                    subtitle: "Block your biggest triggers",
                    color: Color(red: 0.20, green: 0.60, blue: 1.0)
                )
            }
            HStack(spacing: 10) {
                FeatureCard(
                    icon: "flame.fill",
                    title: "Hard & Expert",
                    subtitle: "Unlock all challenge levels",
                    color: Color(red: 1.0, green: 0.42, blue: 0.22)
                )
                FeatureCard(
                    icon: "chart.bar.fill",
                    title: "Full Stats",
                    subtitle: "Track progress over time",
                    color: Color(red: 0.22, green: 0.80, blue: 0.55)
                )
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
                    badgeColor: yearlyHasTrial ? Color(red: 0.22, green: 0.80, blue: 0.55) : Color(red: 0.45, green: 0.32, blue: 0.95),
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
                // Loading state
                HStack(spacing: 10) {
                    ProgressView().tint(.white.opacity(0.4))
                    Text("Loading plans…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if storeManager.products.isEmpty {
                // Error/empty state — show a retry button
                VStack(spacing: 12) {
                    Text(storeManager.productsLoadError != nil
                         ? "Couldn't load plans."
                         : "No plans available.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.50))
                    Button {
                        Task { await storeManager.requestProducts() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.10), in: Capsule())
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
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: selectedProduct?.id == yearlyID && yearlyHasTrial ? "gift.fill" : "lock.open.fill")
                            Text(ctaLabel)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.52, green: 0.38, blue: 1.0), Color(red: 0.32, green: 0.20, blue: 0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: .rect(cornerRadius: 16)
                )
                .shadow(color: Color(red: 0.45, green: 0.32, blue: 0.95).opacity(0.40), radius: 18, y: 6)
            }
            .disabled(isPurchasing || isRestoring || selectedProduct == nil)
            .alert("Purchase Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }

            // Sub-note under CTA
            if selectedProduct?.id == yearlyID, yearlyHasTrial {
                Text("No charge today. Trial ends after 7 days.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
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
                    if isRestoring { ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.8) }
                    Text("Restore Purchases")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                        .underline()
                }
            }
            .disabled(isRestoring || isPurchasing)

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the period ends. Cancel anytime in your Apple ID settings.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://musamasalla.github.io/SoberSend/privacy.html")!)
                Text("·").foregroundStyle(.white.opacity(0.2))
                Link("Terms of Service", destination: URL(string: "https://musamasalla.github.io/SoberSend/terms.html")!)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.3))
            .padding(.top, 4)
        }
        .padding(.top, 20)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, Color(red: 0.22, green: 0.80, blue: 0.55)], startPoint: .top, endPoint: .bottom)
                    )
                Text("You're Premium! 🎉")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("All features are now unlocked.\nStay strong tonight.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                Button("Let's Go →") { dismiss() }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 52)
                    .background(Color(red: 0.45, green: 0.32, blue: 0.95), in: .rect(cornerRadius: 16))
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
            // Silently ignore user cancellation
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.14), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
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
                            isSelected ? Color(red: 0.52, green: 0.38, blue: 1.0) : Color.white.opacity(0.22),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.52, green: 0.38, blue: 1.0))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(badgeColor, in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.50))
                }

                Spacer(minLength: 4)

                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                isSelected
                    ? Color(red: 0.52, green: 0.38, blue: 1.0).opacity(0.16)
                    : Color.white.opacity(0.04),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color(red: 0.52, green: 0.38, blue: 1.0) : Color.white.opacity(0.09),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
