import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var attempts: [ChallengeAttempt]
    @Environment(StoreManager.self) private var storeManager
    
    @State private var showPaywall = false
    @State private var animateHero = false
    
    var totalBlocks: Int { attempts.filter { !$0.passed }.count }
    var totalSaves: Int { attempts.filter { !$0.unlockGranted }.count }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streakDays = 0
        var checkDate = calendar.startOfDay(for: Date())
        for _ in 0..<30 {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayAttempts = attempts.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            if dayAttempts.isEmpty { checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!; continue }
            if dayAttempts.contains(where: { $0.unlockGranted }) { break }
            streakDays += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streakDays
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                heroCard
                streakCard
                achievementsSection
                activitySection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(SoberTheme.background.ignoresSafeArea())
        .navigationTitle("Stats")
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateHero = true
            }
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        PastelAccentCard(bgColor: SoberTheme.mintCard) {
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 44))
                    .foregroundStyle(SoberTheme.mintText)
                    .scaleEffect(animateHero ? 1.0 : 0.5)
                    .opacity(animateHero ? 1.0 : 0)
                
                Text("\(totalBlocks)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(SoberTheme.mintText)
                    .contentTransition(.numericText())
                
                Text("disasters averted")
                    .font(SoberTheme.body())
                    .foregroundStyle(SoberTheme.mintText.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SoberTheme.peachCard)
                    .frame(width: 56, height: 56)
                Text("🔥").font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentStreak) night\(currentStreak == 1 ? "" : "s")")
                    .font(SoberTheme.headline(22))
                    .foregroundStyle(SoberTheme.textPrimary)
                Text("without a regrettable text")
                    .font(SoberTheme.caption())
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            Spacer()
        }
        .soberCard()
    }
    
    // MARK: - Achievements
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Achievements", icon: "trophy.fill")
            
            VStack(spacing: 8) {
                badgeRow(emoji: "🛡️", title: "First Save", desc: "Survived the first attempt", unlocked: totalBlocks >= 1)
                badgeRow(emoji: "🔥", title: "7-Night Streak", desc: "A full week of clean sends", unlocked: currentStreak >= 7, premium: true)
                badgeRow(emoji: "💪", title: "30-Night Streak", desc: "A whole month — legend", unlocked: currentStreak >= 30, premium: true)
                badgeRow(emoji: "🎉", title: "Survived the Weekend", desc: "Made it through Fri & Sat", unlocked: hasSurvivedWeekend, premium: true)
                badgeRow(emoji: "💔", title: "Ex-Free Zone", desc: "10 blocks without caving", unlocked: totalBlocks >= 10)
            }
        }
    }
    
    // MARK: - Activity
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SoberSectionHeader(title: "Recent Activity", icon: "clock.fill")
                Spacer()
                if !storeManager.isPremium {
                    SoberPill(text: "FULL IN PREMIUM", bgColor: SoberTheme.lavenderCard, fgColor: SoberTheme.lavenderText, small: true)
                }
            }
            
            let displayAttempts = storeManager.isPremium ? Array(attempts.prefix(20)) : Array(attempts.prefix(3))
            
            if displayAttempts.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SoberTheme.textSecondary)
                        Text("No activity yet")
                            .font(SoberTheme.body())
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .soberCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayAttempts.enumerated()), id: \.element.id) { index, attempt in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(attempt.unlockGranted ? SoberTheme.peachCard : SoberTheme.mintCard)
                                    .frame(width: 36, height: 36)
                                Image(systemName: attempt.unlockGranted ? "exclamationmark.triangle.fill" : "shield.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(attempt.unlockGranted ? SoberTheme.peachText : SoberTheme.mintText)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attempt.contactOrApp)
                                    .font(SoberTheme.headline(14))
                                    .foregroundStyle(SoberTheme.textPrimary)
                                Text(attempt.timestamp, style: .relative)
                                    .font(SoberTheme.caption())
                                    .foregroundStyle(SoberTheme.textSecondary)
                            }
                            Spacer()
                            SoberPill(
                                text: attempt.unlockGranted ? "Got through" : "Blocked",
                                bgColor: attempt.unlockGranted ? SoberTheme.peachCard : SoberTheme.mintCard,
                                fgColor: attempt.unlockGranted ? SoberTheme.peachText : SoberTheme.mintText,
                                small: true
                            )
                        }
                        .padding(.vertical, 10)
                        if index < displayAttempts.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .soberCard()
                
                if !storeManager.isPremium && attempts.count > 3 {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill").foregroundStyle(SoberTheme.lavenderText)
                            Text("Upgrade to see \(attempts.count) entries").font(SoberTheme.caption()).foregroundStyle(SoberTheme.lavenderText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var hasSurvivedWeekend: Bool {
        let calendar = Calendar.current
        guard !attempts.isEmpty else { return false }
        let weekendAttempts = attempts.filter {
            let weekday = calendar.component(.weekday, from: $0.timestamp)
            return weekday == 6 || weekday == 7
        }
        return !weekendAttempts.isEmpty && !weekendAttempts.contains { $0.unlockGranted }
    }
    
    @ViewBuilder
    private func badgeRow(emoji: String, title: String, desc: String, unlocked: Bool, premium: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 28))
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.4)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(SoberTheme.headline(14))
                        .foregroundStyle(SoberTheme.textPrimary)
                    if premium && !storeManager.isPremium {
                        SoberPill(text: "PRO", bgColor: SoberTheme.lavenderCard, fgColor: SoberTheme.lavenderText, small: true)
                    }
                }
                Text(desc)
                    .font(SoberTheme.caption())
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            Spacer()
            if premium && !storeManager.isPremium && !unlocked {
                Button("Unlock") { showPaywall = true }.font(SoberTheme.caption()).foregroundStyle(SoberTheme.lavenderText)
            } else {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock")
                    .foregroundStyle(unlocked ? SoberTheme.mintText : SoberTheme.textSecondary)
            }
        }
        .soberCard(padding: 14)
    }
}
