import SwiftUI
import SwiftData

// MARK: - Shareable Card View (rendered to image)
struct MorningReportCardView: View {
    let saves: Int
    let streak: Int
    let date: Date
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                HStack {
                    Text("🔒 SoberSend")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(date, format: .dateTime.weekday(.wide).month().day())
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                VStack(spacing: 8) {
                    Text(saves > 0 ? "🛡️" : "✨").font(.system(size: 48))
                    Text(saves > 0
                         ? "Blocked \(saves) regrettable \(saves == 1 ? "message" : "messages")"
                         : "Survived the night without sending anything regrettable")
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Text(saves > 0 ? "You'll thank yourself this morning." : "You're basically a saint.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🔥 \(streak) night streak")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.orange)
                        Text("sobersend.app")
                            .font(.system(size: 11)).foregroundColor(.white.opacity(0.3))
                    }
                    Spacer()
                    Text("I survived another night 💪")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(24)
        }
        .frame(width: 360, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
    
    var body: some View {
        List {
            if overnightAttempts.isEmpty {
                VStack(alignment: .center, spacing: 16) {
                    Text("🛡️").font(.system(size: 60))
                    Text("No regrettable decisions attempted last night.")
                        .font(.headline).multilineTextAlignment(.center)
                    Text("You're a responsible adult. Boring.")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                // Summary
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Last Night's Damage Report").font(.title2).bold()
                        Text(saves > 0
                             ? "SoberSend blocked you \(saves) time\(saves == 1 ? "" : "s"). Nice save. 🛡️"
                             : "You passed your challenges. Hope it was worth it. 😅")
                    }
                    .padding(.vertical, 10)
                }
                
                // Shareable card — PREMIUM ONLY
                Section("Share Your Survival") {
                    VStack(spacing: 12) {
                        MorningReportCardView(saves: saves, streak: currentStreak, date: Date())
                            .cornerRadius(16)
                            .overlay(
                                // Paywall overlay for free users
                                !storeManager.isPremium
                                ? AnyView(
                                    ZStack {
                                        Color.black.opacity(0.6).cornerRadius(16)
                                        VStack(spacing: 6) {
                                            Image(systemName: "lock.fill").font(.largeTitle).foregroundColor(.white)
                                            Text("Premium Feature").font(.headline).foregroundColor(.white)
                                            Text("Upgrade to share your report").font(.caption).foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                )
                                : AnyView(EmptyView())
                            )
                        
                        Button(action: {
                            if storeManager.isPremium {
                                renderAndShare()
                            } else {
                                showPaywall = true
                            }
                        }) {
                            Label(
                                storeManager.isPremium ? "Share Card" : "⭐️ Upgrade to Share",
                                systemImage: storeManager.isPremium ? "square.and.arrow.up" : "lock.fill"
                            )
                            .font(.headline).bold()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(storeManager.isPremium ? Color.white : Color.orange, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                
                // Logs
                Section("The Logs") {
                    ForEach(overnightAttempts) { attempt in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tried to unlock \(attempt.contactOrApp)").font(.headline)
                                Text(attempt.timestamp, format: .dateTime.hour().minute())
                                    .font(.subheadline).foregroundColor(.gray)
                            }
                            Spacer()
                            Text(attempt.unlockGranted ? "Got Through 😬" : "Blocked 🛡️")
                                .foregroundColor(attempt.unlockGranted ? .orange : .green)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Morning Report ☀️")
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $isShowingShareSheet) {
            if let img = shareImage {
                ShareSheet(activityItems: [img, "I survived another night with SoberSend 🔒 #SoberSend #NoRegrets"])
            }
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

// MARK: - UIActivityViewController wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
