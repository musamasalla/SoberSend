import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var attempts: [ChallengeAttempt]
    
    var totalBlocks: Int {
        attempts.filter { !$0.passed }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                VStack(spacing: 20) {
                    Text("Total Disasters Averted")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(totalBlocks)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(totalBlocks > 0 ? .green : .white)
                    
                    Text("times SoberSend stepped in.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
                
                Section("Achievements") {
                    HStack {
                        Text("🛡️")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("First Save")
                                .font(.headline)
                            Text("Survived the first attempt")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if totalBlocks > 0 {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Stats 📊")
        }
        .preferredColorScheme(.dark)
    }
}
