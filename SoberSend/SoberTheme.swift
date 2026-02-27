import SwiftUI

// MARK: - SoberSend Light Pastel Design System
// Inspired by Drops / Duolingo — light, airy, clean, playful.

enum SoberTheme {
    
    // MARK: - Core Colors
    
    /// Page background — pale ice-blue
    static let background = Color(red: 0.92, green: 0.96, blue: 0.98)    // #EBF4FA
    /// Card surface — pure white
    static let card = Color.white
    /// Primary text — near-black
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)   // #1A1A1A
    /// Secondary text — medium gray
    static let textSecondary = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
    /// CTA / primary button — black
    static let ctaBlack = Color(red: 0.10, green: 0.10, blue: 0.10)      // #1A1A1A
    
    // MARK: - Pastel Accent Cards
    
    /// Soft lavender — lock, primary accent
    static let lavenderCard = Color(red: 0.91, green: 0.88, blue: 0.97)  // #E8E0F8
    static let lavenderText = Color(red: 0.45, green: 0.35, blue: 0.70)  // #735AB3
    
    /// Soft mint — success, streaks, safe
    static let mintCard = Color(red: 0.83, green: 0.96, blue: 0.91)      // #D4F5E9
    static let mintText = Color(red: 0.18, green: 0.55, blue: 0.38)      // #2E8C60
    
    /// Soft peach — danger, warnings, locked
    static let peachCard = Color(red: 1.00, green: 0.88, blue: 0.86)     // #FFE0DC
    static let peachText = Color(red: 0.70, green: 0.30, blue: 0.25)     // #B34D40
    
    /// Soft cream — highlights, info
    static let creamCard = Color(red: 1.00, green: 0.97, blue: 0.91)     // #FFF8E7
    static let creamText = Color(red: 0.60, green: 0.50, blue: 0.25)     // #998040
    
    /// Soft blue — secondary info
    static let blueCard = Color(red: 0.85, green: 0.92, blue: 0.98)      // #D9EBFA
    static let blueText = Color(red: 0.20, green: 0.45, blue: 0.70)      // #3373B3
    
    // MARK: - Fonts (Rounded)
    
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - White Card Modifier (with shadow)

struct SoberCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func soberCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(SoberCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Black CTA Button Style

struct SoberPrimaryButtonStyle: ButtonStyle {
    var color: Color = SoberTheme.ctaBlack
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoberTheme.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SoberSecondaryButtonStyle: ButtonStyle {
    var color: Color = SoberTheme.ctaBlack
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoberTheme.headline())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pastel Pill Badge

struct SoberPill: View {
    let text: String
    var bgColor: Color = SoberTheme.lavenderCard
    var fgColor: Color = SoberTheme.lavenderText
    var small: Bool = false
    
    var body: some View {
        Text(text)
            .font(small ? SoberTheme.caption(10) : SoberTheme.caption())
            .fontWeight(.bold)
            .foregroundStyle(fgColor)
            .padding(.horizontal, small ? 8 : 10)
            .padding(.vertical, small ? 3 : 5)
            .background(bgColor, in: Capsule())
    }
}

// MARK: - Section Header

struct SoberSectionHeader: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            Text(title)
                .font(SoberTheme.caption())
                .foregroundStyle(SoberTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Animated Lock Icon (Light version)

struct AnimatedLockIcon: View {
    let isActive: Bool
    @State private var glowAmount: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            // Soft pastel circle
            Circle()
                .fill(isActive ? SoberTheme.peachCard : SoberTheme.mintCard)
                .frame(width: 80, height: 80)
                .scaleEffect(isActive ? (0.95 + glowAmount * 0.1) : 1.0)
            
            Image(systemName: isActive ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(isActive ? SoberTheme.peachText : SoberTheme.mintText)
                .symbolEffect(.bounce, value: isActive)
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowAmount = 1.0
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowAmount = 1.0
                }
            } else {
                withAnimation { glowAmount = 0.3 }
            }
        }
    }
}

// MARK: - Custom Tab Bar (Light)

struct SoberTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var tabNS
    
    private let tabs: [(icon: String, label: String)] = [
        ("lock.shield.fill", "Lockdown"),
        ("sunrise.fill", "Report"),
        ("chart.bar.fill", "Stats"),
        ("gearshape.fill", "Settings")
    ]
    
    private let tabColors: [Color] = [
        SoberTheme.lavenderCard,
        SoberTheme.creamCard,
        SoberTheme.mintCard,
        SoberTheme.blueCard
    ]
    
    private let tabIconColors: [Color] = [
        SoberTheme.lavenderText,
        SoberTheme.creamText,
        SoberTheme.mintText,
        SoberTheme.blueText
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(tabColors[index])
                                    .frame(width: 56, height: 32)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNS)
                            }
                            
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundStyle(selectedTab == index ? tabIconColors[index] : SoberTheme.textSecondary)
                        }
                        .frame(height: 32)
                        
                        Text(tabs[index].label)
                            .font(SoberTheme.caption(10))
                            .foregroundStyle(selectedTab == index ? tabIconColors[index] : SoberTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 4)
        .background(
            SoberTheme.card
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        )
    }
}

// MARK: - Pastel Accent Card

struct PastelAccentCard<Content: View>: View {
    let bgColor: Color
    let cornerRadius: CGFloat
    let content: Content
    
    init(bgColor: Color, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.bgColor = bgColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(bgColor, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
