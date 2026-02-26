import SwiftUI
import SwiftData

struct MorningReportView: View {
    @Query(sort: \ChallengeAttempt.timestamp, order: .reverse) private var attempts: [ChallengeAttempt]
    
    // Filter for only the last 12 hours (overnight)
    private var overnightAttempts: [ChallengeAttempt] {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        return attempts.filter { $0.timestamp > twelveHoursAgo }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if overnightAttempts.isEmpty {
                    VStack(alignment: .center, spacing: 20) {
                        Text("🛡️")
                            .font(.system(size: 60))
                        Text("No regrettable decisions attempted last night.")
                            .font(.headline)
                        Text("You're a responsible adult. Boring.")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        // Summary Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last Night's Damage Report")
                                .font(.title2)
                                .bold()
                            
                            let saves = overnightAttempts.filter { !$0.passed }.count
                            if saves > 0 {
                                Text("SoberSend blocked you \(saves) time(s). Nice save. 🛡️")
                            } else {
                                Text("You passed your challenges. Hope it was an emergency. 😅")
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    Section("The Logs") {
                        ForEach(overnightAttempts) { attempt in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Tried to unlock \(attempt.contactOrApp)")
                                        .font(.headline)
                                    Text(attempt.timestamp, format: .dateTime.hour().minute())
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if attempt.passed {
                                    Text("Passed ❌")
                                        .foregroundColor(.red)
                                } else {
                                    Text("Failed ✅")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Morning Report ☀️")
        }
        .preferredColorScheme(.dark)
    }
}
