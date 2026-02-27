import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var attempts: [ChallengeAttempt]
    @Environment(StoreManager.self) private var storeManager
    
    @State private var showPaywall = false
    
    var totalBlocks: Int { attempts.filter { !$0.passed }.count }
    
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
                overviewSection
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
    }
    
    // MARK: - Overview (grouped card like Settings)
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Overview", icon: "chart.bar.fill")
            
            VStack(spacing: 0) {
                // Blocks stat
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(SoberTheme.mintCard).frame(width: 40, height: 40)
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SoberTheme.mintText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Disasters Averted")
                            .font(SoberTheme.headline())
                            .foregroundStyle(SoberTheme.textPrimary)
                        Text("Times SoberSend saved you")
                            .font(SoberTheme.caption())
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(totalBlocks)")
                        .font(SoberTheme.title(28))
                        .foregroundStyle(SoberTheme.mintText)
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 4)
                
                Divider().padding(.leading, 52)
                
                // Streak stat
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(SoberTheme.peachCard).frame(width: 40, height: 40)
                        Text("🔥").font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Streak")
                            .font(SoberTheme.headline())
                            .foregroundStyle(SoberTheme.textPrimary)
                        Text("Without a regrettable text")
                            .font(SoberTheme.caption())
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(currentStreak)")
                        .font(SoberTheme.title(28))
                        .foregroundStyle(SoberTheme.peachText)
                }
                .padding(.vertical, 4)
            }
            .soberCard()
        }
    }
    
    // MARK: - Achievements (grouped in ONE card)
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Achievements", icon: "trophy.fill")
            
            VStack(spacing: 0) {
                badgeRow(emoji: "🛡️", title: "First Save", desc: "Survived the first attempt", unlocked: totalBlocks >= 1, isLast: false)
                badgeRow(emoji: "🔥", title: "7-Night Streak", desc: "A full week of clean sends", unlocked: currentStreak >= 7, premium: true, isLast: false)
                badgeRow(emoji: "💪", title: "30-Night Streak", desc: "A whole month — legend", unlocked: currentStreak >= 30, premium: true, isLast: false)
                badgeRow(emoji: "🎉", title: "Survived Weekend", desc: "Made it through Fri & Sat", unlocked: hasSurvivedWeekend, premium: true, isLast: false)
                badgeRow(emoji: "💔", title: "Ex-Free Zone", desc: "10 blocks without caving", unlocked: totalBlocks >= 10, isLast: true)
            }
            .soberCard(padding: 0)
        }
    }
    
    // MARK: - Activity (grouped in ONE card)
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SoberSectionHeader(title: "Recent Activity", icon: "clock.fill")
                Spacer()
                if !storeManager.isPremium {
                    SoberPill(text: "PRO", bgColor: SoberTheme.lavenderCard, fgColor: SoberTheme.lavenderText, small: true)
                }
            }
            
            let displayAttempts = storeManager.isPremium ? Array(attempts.prefix(20)) : Array(attempts.prefix(3))
            
            if displayAttempts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(SoberTheme.textSecondary.opacity(0.5))
                    Text("No activity yet")
                        .font(SoberTheme.body())
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
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
                        .padding(.horizontal, 16)
                        if index < displayAttempts.count - 1 {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
                
                if !storeManager.isPremium && attempts.count > 3 {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill").font(.caption).foregroundStyle(SoberTheme.lavenderText)
                            Text("See all \(attempts.count) entries")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.lavenderText)
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
    private func badgeRow(emoji: String, title: String, desc: String, unlocked: Bool, premium: Bool = false, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 24))
                    .grayscale(unlocked ? 0 : 1)
                    .opacity(unlocked ? 1 : 0.4)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
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
                    Button("Unlock") { showPaywall = true }
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.lavenderText)
                } else {
                    Image(systemName: unlocked ? "checkmark.seal.fill" : "lock")
                        .foregroundStyle(unlocked ? SoberTheme.mintText : SoberTheme.textSecondary.opacity(0.4))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            
            if !isLast { Divider().padding(.leading, 68) }
        }
    }
}
