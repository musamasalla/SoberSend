import SwiftUI

// MARK: - SoberSend Pastel Dark Design System

/// "Soft Rebellion" — calm pastels on deep charcoal.
/// A caring friend, not a drill sergeant.
enum SoberTheme {
    
    // MARK: - Color Palette
    
    /// Primary accent — used for buttons, active states, selections
    static let lavender = Color(red: 0.72, green: 0.66, blue: 0.91)      // #B8A9E8
    /// Success states — streaks, completed, safe
    static let mint = Color(red: 0.66, green: 0.90, blue: 0.81)           // #A8E6CF
    /// Danger/warning — locked, alerts, peach warmth
    static let peach = Color(red: 1.00, green: 0.72, blue: 0.70)          // #FFB7B2
    /// Info, secondary accent
    static let skyBlue = Color(red: 0.68, green: 0.78, blue: 0.81)        // #AEC6CF
    /// Highlight text, warm emphasis
    static let cream = Color(red: 1.00, green: 0.96, blue: 0.89)          // #FFF5E4
    /// Deep background — NOT pure black
    static let charcoal = Color(red: 0.10, green: 0.10, blue: 0.18)       // #1A1A2E
    /// Card / panel surface
    static let surface = Color(red: 0.145, green: 0.145, blue: 0.25)      // #252540
    /// Elevated / hover surface
    static let surfaceBright = Color(red: 0.185, green: 0.185, blue: 0.31) // #2F2F50
    /// Muted text
    static let textSecondary = Color.white.opacity(0.55)
    /// Subtle borders
    static let border = Color.white.opacity(0.08)
    
    // MARK: - Semantic Colors
    
    /// Active lockdown state
    static let lockActive = peach
    /// Inactive / safe state
    static let lockInactive = mint
    /// Premium feature highlight
    static let premium = lavender
    /// Destructive / emergency
    static let danger = Color(red: 1.0, green: 0.55, blue: 0.55)
    
    // MARK: - Fonts
    
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

// MARK: - Card Modifier

struct SoberCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SoberTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(SoberTheme.border, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func soberCard(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(SoberCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Primary Button Style

struct SoberPrimaryButtonStyle: ButtonStyle {
    var color: Color = SoberTheme.lavender
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoberTheme.headline())
            .foregroundColor(SoberTheme.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SoberSecondaryButtonStyle: ButtonStyle {
    var color: Color = SoberTheme.lavender
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoberTheme.headline())
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
                    .fill(color.opacity(0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pill Badge

struct SoberPill: View {
    let text: String
    var color: Color = SoberTheme.lavender
    var small: Bool = false
    
    var body: some View {
        Text(text)
            .font(small ? SoberTheme.caption(10) : SoberTheme.caption())
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, small ? 8 : 10)
            .padding(.vertical, small ? 3 : 5)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Animated Lock Icon

struct AnimatedLockIcon: View {
    let isActive: Bool
    @State private var glowAmount: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            // Glow ring
            if isActive {
                Circle()
                    .fill(SoberTheme.peach.opacity(glowAmount * 0.4))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)
            }
            
            // Icon
            Image(systemName: isActive ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(isActive ? SoberTheme.peach : SoberTheme.mint)
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

// MARK: - Section Header

struct SoberSectionHeader: View {
    let title: String
    var icon: String? = nil
    var color: Color = SoberTheme.textSecondary
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            Text(title)
                .font(SoberTheme.caption())
                .foregroundColor(color)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Floating Orbs Background

struct FloatingOrbsBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            SoberTheme.charcoal.ignoresSafeArea()
            
            // Subtle floating pastel orbs
            Circle()
                .fill(SoberTheme.lavender.opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -80, y: -200 + sin(phase) * 20)
            
            Circle()
                .fill(SoberTheme.mint.opacity(0.05))
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .offset(x: 100, y: 100 + cos(phase) * 15)
            
            Circle()
                .fill(SoberTheme.peach.opacity(0.04))
                .frame(width: 180, height: 180)
                .blur(radius: 55)
                .offset(x: -60, y: 300 + sin(phase * 0.7) * 25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct SoberTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var tabNamespace
    
    private let tabs: [(icon: String, label: String)] = [
        ("lock.shield.fill", "Lockdown"),
        ("sunrise.fill", "Report"),
        ("chart.bar.fill", "Stats"),
        ("gearshape.fill", "Settings")
    ]
    
    private let tabColors: [Color] = [
        SoberTheme.peach,
        SoberTheme.cream,
        SoberTheme.mint,
        SoberTheme.skyBlue
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(tabColors[index].opacity(0.18))
                                    .frame(width: 56, height: 32)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                            }
                            
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? tabColors[index] : SoberTheme.textSecondary)
                        }
                        .frame(height: 32)
                        
                        Text(tabs[index].label)
                            .font(SoberTheme.caption(10))
                            .foregroundColor(selectedTab == index ? tabColors[index] : SoberTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 4) // Safe area will add more
        .background(
            SoberTheme.surface
                .overlay(
                    Rectangle()
                        .fill(SoberTheme.border)
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }
}

// MARK: - Pastel Toggle Style

struct SoberToggleStyle: ToggleStyle {
    var onColor: Color = SoberTheme.lavender
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Capsule()
                .fill(configuration.isOn ? onColor.opacity(0.3) : SoberTheme.border)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(configuration.isOn ? onColor : Color.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10),
                    alignment: .center
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
