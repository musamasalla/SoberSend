import SwiftUI

struct ChallengeCoordinatorView: View {
    let contactOrAppName: String
    let difficulty: ChallengeDifficulty
    let soberNote: String?
    let onResult: (Bool) -> Void
    
    @State private var currentStage: Int = 0
    // The exact sequence of tests to perform
    @State private var sequence: [ChallengeType] = []
    
    @Environment(EmergencyUnlockManager.self) private var emergencyManager
    @State private var showEmergencyUnlock = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if sequence.isEmpty {
                    ProgressView()
                } else if currentStage < sequence.count {
                    let currentType = sequence[currentStage]
                    
                    VStack {
                        if let note = soberNote, !note.isEmpty {
                            Text("Note from sober you: \"\(note)\"")
                                .font(.callout)
                                .italic()
                                .foregroundColor(.yellow)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal)
                        }
                        
                        switch currentType {
                        case .math:
                            MathChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed)
                            }
                        case .memory:
                            MemoryChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed)
                            }
                        case .speech:
                            SpeechChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed)
                            }
                        default:
                            Text("Unknown challenge.")
                        }
                    }
                }
            }
            .navigationTitle("Unlocking \(contactOrAppName)")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Emergency") {
                        showEmergencyUnlock = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showEmergencyUnlock, onDismiss: {
            if emergencyManager.isEmergencyUnlocked {
                onResult(true) // Treat as pass if unlocked
            }
        }) {
            EmergencyUnlockView()
        }
        .onAppear(perform: setupSequence)
    }
    
    private func setupSequence() {
        switch difficulty {
        case .easy:
            sequence = [.math]
        case .medium:
            sequence = [.math, .memory]
        case .hard:
            sequence = [.math, .speech]
        case .expert:
            sequence = [.math, .memory, .speech]
        }
    }
    
    private func handleResult(passed: Bool) {
        if passed {
            currentStage += 1
            if currentStage >= sequence.count {
                onResult(true) // All passed
            }
        } else {
            onResult(false) // Failed at this stage
        }
    }
}
