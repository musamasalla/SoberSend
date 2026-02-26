import SwiftUI
import SwiftData

struct ChallengeCoordinatorView: View {
    let contactOrAppName: String
    let difficulty: ChallengeDifficulty
    let soberNote: String?
    let onResult: (Bool) -> Void
    
    @State private var currentStage: Int = 0
    @State private var sequence: [ChallengeType] = []
    
    @Environment(EmergencyUnlockManager.self) private var emergencyManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @State private var showEmergencyUnlock = false
    
    // 10-min lockout
    @AppStorage("challengeLockoutEnd", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var lockoutEndTimestamp: Double = 0
    @State private var isLockedOut = false
    @State private var lockoutRemaining: TimeInterval = 0
    @State private var lockoutTimer: Timer?
    
    // Fallback global soberNote
    @AppStorage("soberNote", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var globalSoberNote: String = ""
    
    private var displayNote: String? {
        if let note = soberNote, !note.isEmpty { return note }
        if !globalSoberNote.isEmpty { return globalSoberNote }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLockedOut {
                    lockoutView
                } else if sequence.isEmpty {
                    ProgressView()
                } else if currentStage < sequence.count {
                    let currentType = sequence[currentStage]
                    
                    VStack(spacing: 0) {
                        // Sober note banner
                        if let note = displayNote {
                            HStack(spacing: 8) {
                                Text("📝")
                                Text("Sober you says: \"\(note)\"")
                                    .font(.callout)
                                    .italic()
                            }
                            .foregroundColor(.yellow)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        // Progress indicator
                        if sequence.count > 1 {
                            HStack(spacing: 6) {
                                ForEach(0..<sequence.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i < currentStage ? Color.green : (i == currentStage ? Color.blue : Color.gray.opacity(0.3)))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 12)
                        }
                        
                        switch currentType {
                        case .math:
                            MathChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed, type: .math)
                            }
                        case .memory:
                            MemoryChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed, type: .memory)
                            }
                        case .speech:
                            SpeechChallengeView(difficulty: difficulty) { passed in
                                handleResult(passed: passed, type: .speech)
                            }
                        case .combined:
                            Text("Processing...")
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
                onResult(true)
            }
        }) {
            EmergencyUnlockView()
        }
        .onAppear {
            checkLockout()
            if !isLockedOut { setupSequence() }
        }
        .onDisappear {
            lockoutTimer?.invalidate()
        }
    }
    
    // MARK: - Lockout View
    private var lockoutView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🔒")
                .font(.system(size: 60))
            
            Text("\(contactOrAppName) is locked")
                .font(.title2)
                .bold()
            
            Text("You'll thank yourself tomorrow.")
                .foregroundColor(.gray)
            
            Text(lockoutTimeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
            
            Text("remaining")
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Go Back") {
                onResult(false)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    private var lockoutTimeString: String {
        let minutes = Int(lockoutRemaining) / 60
        let seconds = Int(lockoutRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Lockout Logic
    private func checkLockout() {
        let now = Date().timeIntervalSince1970
        if lockoutEndTimestamp > now {
            isLockedOut = true
            lockoutRemaining = lockoutEndTimestamp - now
            startLockoutTimer()
        }
    }
    
    private func startLockoutTimer() {
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let now = Date().timeIntervalSince1970
            if lockoutEndTimestamp > now {
                lockoutRemaining = lockoutEndTimestamp - now
            } else {
                isLockedOut = false
                lockoutTimer?.invalidate()
                setupSequence()
            }
        }
    }
    
    private func activateLockout() {
        let tenMinutes: TimeInterval = 10 * 60
        lockoutEndTimestamp = Date().timeIntervalSince1970 + tenMinutes
        isLockedOut = true
        lockoutRemaining = tenMinutes
        startLockoutTimer()
    }
    
    // MARK: - Sequence Setup
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
    
    // MARK: - Result Handling
    private func handleResult(passed: Bool, type: ChallengeType) {
        let attempt = ChallengeAttempt(
            contactOrApp: contactOrAppName,
            passed: passed,
            challengeType: type,
            attemptNumber: currentStage + 1,
            unlockGranted: false
        )
        modelContext.insert(attempt)
        
        if passed {
            currentStage += 1
            if currentStage >= sequence.count {
                attempt.unlockGranted = true
                try? modelContext.save()
                onResult(true)
            }
        } else {
            try? modelContext.save()
            // Activate 10-minute lockout on failure
            activateLockout()
        }
    }
}
