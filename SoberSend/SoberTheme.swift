import SwiftUI

// MARK: - SoberSend Adaptive Design System
// Supports light + dark mode via UIColor trait collections.
// Settings page is the gold standard for card grouping.

enum SoberTheme {
    
    // MARK: - Adaptive Color Helper
    
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    
    // MARK: - Core Colors
    
    /// Page background
    static let background = adaptive(
        light: UIColor(red: 0.92, green: 0.96, blue: 0.98, alpha: 1),
        dark:  UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)  // #121214
    )
    /// Card surface
    static let card = adaptive(
        light: .white,
        dark:  UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) // #1C1C1E
    )
    /// Primary text
    static let textPrimary = adaptive(
        light: UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
        dark:  UIColor(white: 0.95, alpha: 1)
    )
    /// Secondary text
    static let textSecondary = adaptive(
        light: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1),
        dark:  UIColor(white: 0.55, alpha: 1)
    )
    /// CTA button — inverts for dark mode
    static let ctaBlack = adaptive(
        light: UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
        dark:  UIColor(white: 0.95, alpha: 1)
    )
    /// CTA button text — inverts for dark mode
    static let ctaForeground = adaptive(
        light: .white,
        dark:  UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
    )
    
    // MARK: - Pastel Accents (slightly deepened in dark)
    
    static let lavenderCard = adaptive(
        light: UIColor(red: 0.91, green: 0.88, blue: 0.97, alpha: 1),
        dark:  UIColor(red: 0.22, green: 0.18, blue: 0.35, alpha: 1)
    )
    static let lavenderText = adaptive(
        light: UIColor(red: 0.45, green: 0.35, blue: 0.70, alpha: 1),
        dark:  UIColor(red: 0.70, green: 0.62, blue: 0.92, alpha: 1)
    )
    
    static let mintCard = adaptive(
        light: UIColor(red: 0.83, green: 0.96, blue: 0.91, alpha: 1),
        dark:  UIColor(red: 0.12, green: 0.24, blue: 0.18, alpha: 1)
    )
    static let mintText = adaptive(
        light: UIColor(red: 0.18, green: 0.55, blue: 0.38, alpha: 1),
        dark:  UIColor(red: 0.40, green: 0.80, blue: 0.58, alpha: 1)
    )
    
    static let peachCard = adaptive(
        light: UIColor(red: 1.00, green: 0.88, blue: 0.86, alpha: 1),
        dark:  UIColor(red: 0.30, green: 0.14, blue: 0.12, alpha: 1)
    )
    static let peachText = adaptive(
        light: UIColor(red: 0.70, green: 0.30, blue: 0.25, alpha: 1),
        dark:  UIColor(red: 0.92, green: 0.50, blue: 0.42, alpha: 1)
    )
    
    static let creamCard = adaptive(
        light: UIColor(red: 1.00, green: 0.97, blue: 0.91, alpha: 1),
        dark:  UIColor(red: 0.25, green: 0.22, blue: 0.12, alpha: 1)
    )
    static let creamText = adaptive(
        light: UIColor(red: 0.60, green: 0.50, blue: 0.25, alpha: 1),
        dark:  UIColor(red: 0.85, green: 0.75, blue: 0.42, alpha: 1)
    )
    
    static let blueCard = adaptive(
        light: UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1),
        dark:  UIColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1)
    )
    static let blueText = adaptive(
        light: UIColor(red: 0.20, green: 0.45, blue: 0.70, alpha: 1),
        dark:  UIColor(red: 0.45, green: 0.70, blue: 0.95, alpha: 1)
    )
    
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

// MARK: - Appearance Mode

enum AppearanceMode: Int, CaseIterable {
    case system = 0, light = 1, dark = 2
    
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - White Card Modifier

struct SoberCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

extension View {
    func soberCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(SoberCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Grouped Row Helper (Settings-style)

struct SoberRow: View {
    let icon: String
    let iconBg: Color
    let iconFg: Color
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconBg).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(iconFg)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(SoberTheme.headline()).foregroundStyle(SoberTheme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(SoberTheme.caption()).foregroundStyle(SoberTheme.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
            else { Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(SoberTheme.textSecondary.opacity(0.5)) }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Black CTA Button

struct SoberPrimaryButtonStyle: ButtonStyle {
    var color: Color = SoberTheme.ctaBlack
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoberTheme.headline())
            .foregroundStyle(SoberTheme.ctaForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed)
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
            .background(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

// MARK: - Pill Badge

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

// MARK: - Section Header (Settings-style)

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

// MARK: - Tab Bar (Pill-shaped)

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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == index {
                                Circle()
                                    .fill(tabColors[index])
                                    .frame(width: 44, height: 44)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNS)
                            }
                            
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: selectedTab == index ? 20 : 18, weight: selectedTab == index ? .bold : .regular))
                                .foregroundStyle(selectedTab == index ? tabIconColors[index] : SoberTheme.textSecondary.opacity(0.6))
                        }
                        .frame(height: 44)
                        
                        Text(tabs[index].label)
                            .font(SoberTheme.caption(10))
                            .fontWeight(selectedTab == index ? .bold : .medium)
                            .foregroundStyle(selectedTab == index ? tabIconColors[index] : SoberTheme.textSecondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            SoberTheme.card
                .shadow(color: .black.opacity(0.06), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
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
