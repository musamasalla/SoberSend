import SwiftUI
import SwiftData

// MARK: - Shareable Card View (rendered to image)
struct MorningReportCardView: View {
    let saves: Int
    let streak: Int
    let date: Date
    
    var body: some View {
        ZStack {
            // Soft pastel background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [SoberTheme.charcoal, SoberTheme.surface],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(SoberTheme.lavender.opacity(0.2), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(SoberTheme.lavender)
                        Text("SoberSend")
                            .font(SoberTheme.caption())
                            .foregroundColor(SoberTheme.lavender)
                    }
                    Spacer()
                    Text(date, format: .dateTime.weekday(.wide).month().day())
                        .font(SoberTheme.caption(11))
                        .foregroundColor(SoberTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(saves > 0 ? "🛡️" : "✨").font(.system(size: 44))
                    Text(saves > 0
                         ? "Blocked \(saves) regrettable \(saves == 1 ? "message" : "messages")"
                         : "Survived the night clean")
                        .font(SoberTheme.headline(18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Text(saves > 0 ? "You'll thank yourself this morning." : "You're basically a saint.")
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.textSecondary)
                }
                
                Spacer()
                
                HStack {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text("\(streak) night streak")
                            .font(SoberTheme.caption(12))
                            .foregroundColor(SoberTheme.peach)
                    }
                    Spacer()
                    Text("I survived another night 💪")
                        .font(SoberTheme.caption(11))
                        .foregroundColor(SoberTheme.textSecondary)
                }
            }
            .padding(24)
        }
        .frame(width: 360, height: 200)
    }
}

// MARK: - Morning Report View
struct MorningReportView: View {
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var attempts: [ChallengeAttempt]
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var allAttempts: [ChallengeAttempt]
    @Environment(StoreManager.self) private var storeManager
    
    @State private var shareImage: UIImage? = nil
    @State private var isShowingShareSheet = false
    @State private var showPaywall = false
    
    private var overnightAttempts: [ChallengeAttempt] {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        return attempts.filter { $0.timestamp > twelveHoursAgo }
    }
    
    private var saves: Int { overnightAttempts.filter { !$0.unlockGranted }.count }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streakDays = 0
        var checkDate = calendar.startOfDay(for: Date())
        for _ in 0..<30 {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayAttempts = allAttempts.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            if dayAttempts.isEmpty { checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!; continue }
            if dayAttempts.contains(where: { $0.unlockGranted }) { break }
            streakDays += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streakDays
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning ☀️" }
        if hour < 17 { return "Good afternoon 🌤️" }
        return "Good evening 🌙"
    }
    
    var body: some View {
        ZStack {
            FloatingOrbsBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if overnightAttempts.isEmpty {
                        emptyState
                    } else {
                        // Greeting
                        Text(greeting)
                            .font(SoberTheme.headline(22))
                            .foregroundColor(SoberTheme.cream)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        
                        // Summary card
                        summaryCard
                        
                        // Share card
                        shareSection
                        
                        // Activity logs
                        logsSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Morning Report")
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $isShowingShareSheet) {
            if let img = shareImage {
                ShareSheet(activityItems: [img, "I survived another night with SoberSend 🔒 #SoberSend #NoRegrets"])
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 50))
                .foregroundColor(SoberTheme.lavender.opacity(0.5))
            
            Text("No activity last night")
                .font(SoberTheme.headline(20))
                .foregroundColor(.white)
            
            Text("You didn't try to unlock anything.\nResponsible. Boring. But responsible.")
                .font(SoberTheme.body())
                .foregroundColor(SoberTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last Night's Damage Report")
                .font(SoberTheme.headline(18))
                .foregroundColor(.white)
            
            Text(saves > 0
                 ? "SoberSend blocked you \(saves) time\(saves == 1 ? "" : "s"). Nice save. 🛡️"
                 : "You passed your challenges. Hope it was worth it. 😅")
                .font(SoberTheme.body())
                .foregroundColor(SoberTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soberCard()
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        VStack(spacing: 12) {
            SoberSectionHeader(title: "Share Your Survival", icon: "square.and.arrow.up", color: SoberTheme.lavender)
            
            ZStack {
                MorningReportCardView(saves: saves, streak: currentStreak, date: Date())
                
                // Premium overlay
                if !storeManager.isPremium {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(SoberTheme.charcoal.opacity(0.75))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundColor(SoberTheme.lavender)
                        Text("Premium Feature")
                            .font(SoberTheme.headline())
                            .foregroundColor(.white)
                        Text("Upgrade to share your report")
                            .font(SoberTheme.caption())
                            .foregroundColor(SoberTheme.textSecondary)
                    }
                }
            }
            .frame(height: 200)
            
            Button(action: {
                if storeManager.isPremium {
                    renderAndShare()
                } else {
                    showPaywall = true
                }
            }) {
                Text(storeManager.isPremium ? "Share Card" : "⭐️ Upgrade to Share")
            }
            .buttonStyle(storeManager.isPremium
                         ? SoberPrimaryButtonStyle(color: SoberTheme.lavender)
                         : SoberPrimaryButtonStyle(color: SoberTheme.lavender))
        }
    }
    
    // MARK: - Logs
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "The Logs", icon: "list.bullet", color: SoberTheme.skyBlue)
            
            VStack(spacing: 0) {
                ForEach(Array(overnightAttempts.enumerated()), id: \.element.id) { index, attempt in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(attempt.unlockGranted ? SoberTheme.peach.opacity(0.15) : SoberTheme.mint.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: attempt.unlockGranted ? "exclamationmark.triangle.fill" : "shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(attempt.unlockGranted ? SoberTheme.peach : SoberTheme.mint)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tried to unlock \(attempt.contactOrApp)")
                                .font(SoberTheme.headline(14))
                                .foregroundColor(.white)
                            Text(attempt.timestamp, format: .dateTime.hour().minute())
                                .font(SoberTheme.caption())
                                .foregroundColor(SoberTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        SoberPill(
                            text: attempt.unlockGranted ? "Got Through" : "Blocked",
                            color: attempt.unlockGranted ? SoberTheme.peach : SoberTheme.mint,
                            small: true
                        )
                    }
                    .padding(.vertical, 10)
                    
                    if index < overnightAttempts.count - 1 {
                        Divider()
                            .background(SoberTheme.border)
                            .padding(.leading, 48)
                    }
                }
            }
            .soberCard()
        }
    }
    
    // MARK: - Render
    
    private func renderAndShare() {
        let card = MorningReportCardView(saves: saves, streak: currentStreak, date: Date())
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let img = renderer.uiImage {
            shareImage = img
            isShowingShareSheet = true
        }
    }
}

// MARK: - UIActivityViewController wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
