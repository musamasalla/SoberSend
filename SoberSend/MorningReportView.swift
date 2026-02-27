import SwiftUI
import SwiftData

// MARK: - Shareable Card View
struct MorningReportCardView: View {
    let saves: Int
    let streak: Int
    let date: Date
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(SoberTheme.card)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(SoberTheme.lavenderText)
                        Text("SoberSend")
                            .font(SoberTheme.caption())
                            .foregroundStyle(SoberTheme.lavenderText)
                    }
                    Spacer()
                    Text(date, format: .dateTime.weekday(.wide).month().day())
                        .font(SoberTheme.caption(11))
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(saves > 0 ? "🛡️" : "✨").font(.system(size: 44))
                    Text(saves > 0
                         ? "Blocked \(saves) regrettable \(saves == 1 ? "message" : "messages")"
                         : "Survived the night clean")
                        .font(SoberTheme.headline(18))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(SoberTheme.textPrimary)
                    Text(saves > 0 ? "You'll thank yourself this morning." : "You're basically a saint.")
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                
                Spacer()
                
                HStack {
                    HStack(spacing: 4) {
                        Text("🔥").font(.system(size: 12))
                        Text("\(streak) night streak")
                            .font(SoberTheme.caption(12))
                            .foregroundStyle(SoberTheme.peachText)
                    }
                    Spacer()
                    Text("I survived another night 💪")
                        .font(SoberTheme.caption(11))
                        .foregroundStyle(SoberTheme.textSecondary)
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if overnightAttempts.isEmpty {
                    emptyState
                } else {
                    Text(greeting)
                        .font(SoberTheme.title(24))
                        .foregroundStyle(SoberTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    
                    summarySection
                    shareSection
                    logsSection
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(SoberTheme.background.ignoresSafeArea())
        .navigationTitle("Morning Report")
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $isShowingShareSheet) {
            if let img = shareImage {
                ShareSheet(activityItems: [img, "I survived another night with SoberSend 🔒 #SoberSend #NoRegrets"])
            }
        }
    }
    
    // MARK: - Empty State (proper card)
    
    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SoberTheme.blueCard)
                        .frame(width: 72, height: 72)
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(SoberTheme.blueText)
                }
                Text("No activity last night")
                    .font(SoberTheme.headline(20))
                    .foregroundStyle(SoberTheme.textPrimary)
                Text("You didn't try to unlock anything.\nResponsible. Boring. But responsible.")
                    .font(SoberTheme.body())
                    .foregroundStyle(SoberTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .soberCard()
            Spacer()
        }
    }
    
    // MARK: - Summary (grouped card like Settings)
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Summary", icon: "doc.text.fill")
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(saves > 0 ? SoberTheme.mintCard : SoberTheme.peachCard).frame(width: 40, height: 40)
                        Image(systemName: saves > 0 ? "shield.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(saves > 0 ? SoberTheme.mintText : SoberTheme.peachText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Night's Damage Report")
                            .font(SoberTheme.headline())
                            .foregroundStyle(SoberTheme.textPrimary)
                        Text(saves > 0
                             ? "Blocked you \(saves) time\(saves == 1 ? "" : "s"). Nice save. 🛡️"
                             : "You passed your challenges. Hope it was worth it. 😅")
                            .font(SoberTheme.caption())
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .soberCard()
        }
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Share Your Survival", icon: "square.and.arrow.up")
            
            VStack(spacing: 0) {
                ZStack {
                    MorningReportCardView(saves: saves, streak: currentStreak, date: Date())
                    
                    if !storeManager.isPremium {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.85))
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(SoberTheme.lavenderCard).frame(width: 48, height: 48)
                                Image(systemName: "lock.fill").font(.title3).foregroundStyle(SoberTheme.lavenderText)
                            }
                            Text("Premium Feature")
                                .font(SoberTheme.headline())
                                .foregroundStyle(SoberTheme.textPrimary)
                            Text("Upgrade to share your report")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.textSecondary)
                        }
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button {
                    if storeManager.isPremium { renderAndShare() } else { showPaywall = true }
                } label: {
                    Text(storeManager.isPremium ? "Share Card" : "⭐️ Upgrade to Share")
                }
                .buttonStyle(SoberPrimaryButtonStyle())
                .padding(.top, 12)
            }
            .soberCard()
        }
    }
    
    // MARK: - Logs (grouped card like Settings)
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "The Logs", icon: "list.bullet")
            
            VStack(spacing: 0) {
                ForEach(Array(overnightAttempts.enumerated()), id: \.element.id) { index, attempt in
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
                            Text("Tried to unlock \(attempt.contactOrApp)")
                                .font(SoberTheme.headline(14))
                                .foregroundStyle(SoberTheme.textPrimary)
                            Text(attempt.timestamp, format: .dateTime.hour().minute())
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.textSecondary)
                        }
                        Spacer()
                        SoberPill(
                            text: attempt.unlockGranted ? "Got Through" : "Blocked",
                            bgColor: attempt.unlockGranted ? SoberTheme.peachCard : SoberTheme.mintCard,
                            fgColor: attempt.unlockGranted ? SoberTheme.peachText : SoberTheme.mintText,
                            small: true
                        )
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    if index < overnightAttempts.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        }
    }
    
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
