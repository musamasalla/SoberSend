import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var attempts: [ChallengeAttempt]
    @Environment(StoreManager.self) private var storeManager
    
    @State private var showPaywall = false
    
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
            if dayAttempts.isEmpty {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }
            if dayAttempts.contains(where: { $0.unlockGranted }) { break }
            streakDays += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streakDays
    }
    
    var body: some View {
        List {
            // Hero stat
            VStack(spacing: 16) {
                Text("🛡️").font(.system(size: 50))
                Text("\(totalBlocks)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(totalBlocks > 0 ? .green : .white)
                Text("disasters averted")
                    .font(.subheadline).foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .listRowBackground(Color.clear)
            
            // Streak
            Section {
                HStack {
                    Text("🔥").font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text("\(currentStreak) night\(currentStreak == 1 ? "" : "s")")
                            .font(.title2).bold()
                        Text("without a regrettable text")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            } header: { Text("Current Streak") }
            
            // Achievements
            Section("Achievements") {
                badgeRow(emoji: "🛡️", title: "First Save", desc: "Survived the first attempt", unlocked: totalBlocks >= 1)
                badgeRow(emoji: "🔥", title: "7-Night Streak", desc: "A full week of clean sends", unlocked: currentStreak >= 7, premium: true)
                badgeRow(emoji: "💪", title: "30-Night Streak", desc: "A whole month — legend", unlocked: currentStreak >= 30, premium: true)
                badgeRow(emoji: "🎉", title: "Survived the Weekend", desc: "Made it through Fri & Sat", unlocked: hasSurvivedWeekend, premium: true)
                badgeRow(emoji: "💔", title: "Ex-Free Zone", desc: "10 blocks without caving", unlocked: totalBlocks >= 10)
            }
            
            // Recent Activity — PREMIUM: full history, FREE: last 3
            Section {
                let displayAttempts = storeManager.isPremium ? Array(attempts.prefix(20)) : Array(attempts.prefix(3))
                
                if displayAttempts.isEmpty {
                    Text("No activity yet")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach(displayAttempts) { attempt in
                        HStack {
                            Text(attempt.unlockGranted ? "😬" : "🛡️").font(.title2)
                            VStack(alignment: .leading) {
                                Text(attempt.contactOrApp).font(.subheadline).bold()
                                Text(attempt.timestamp, style: .relative)
                                    .font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Text(attempt.unlockGranted ? "Got through" : "Blocked")
                                .font(.caption)
                                .foregroundColor(attempt.unlockGranted ? .orange : .green)
                        }
                    }
                    
                    // Prompt free users to upgrade for full history
                    if !storeManager.isPremium && attempts.count > 3 {
                        Button(action: { showPaywall = true }) {
                            HStack {
                                Image(systemName: "lock.fill").foregroundColor(.orange)
                                Text("Upgrade to see full history (\(attempts.count) entries)")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                        .listRowBackground(Color.orange.opacity(0.08))
                    }
                }
            } header: {
                HStack {
                    Text("Recent Activity")
                    Spacer()
                    if !storeManager.isPremium {
                        Text("⭐️ Full history in Premium")
                            .font(.caption2).foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Stats 📊")
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
    
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
        HStack {
            Text(emoji)
                .font(.largeTitle)
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.4)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(title).font(.headline)
                    if premium && !storeManager.isPremium {
                        Text("⭐️").font(.caption)
                    }
                }
                Text(desc).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            if premium && !storeManager.isPremium && !unlocked {
                Button("Unlock") { showPaywall = true }
                    .font(.caption).foregroundColor(.orange)
            } else {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock")
                    .foregroundColor(unlocked ? .green : .gray)
            }
        }
    }
}
