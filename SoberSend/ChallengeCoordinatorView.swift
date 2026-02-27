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
                SoberTheme.charcoal.ignoresSafeArea()
                
                if isLockedOut {
                    lockoutView
                } else if sequence.isEmpty {
                    ProgressView()
                        .tint(SoberTheme.lavender)
                } else if currentStage < sequence.count {
                    let currentType = sequence[currentStage]
                    
                    VStack(spacing: 0) {
                        // Sober note banner
                        if let note = displayNote {
                            HStack(spacing: 8) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 12))
                                    .foregroundColor(SoberTheme.cream)
                                Text("Sober you says: \"\(note)\"")
                                    .font(SoberTheme.body())
                                    .italic()
                                    .foregroundColor(SoberTheme.cream)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(SoberTheme.cream.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SoberTheme.cream.opacity(0.15), lineWidth: 1))
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        // Progress indicator
                        if sequence.count > 1 {
                            HStack(spacing: 6) {
                                ForEach(0..<sequence.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i < currentStage ? SoberTheme.mint : (i == currentStage ? SoberTheme.lavender : SoberTheme.surfaceBright))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
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
                                .foregroundColor(SoberTheme.textSecondary)
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
                    .foregroundColor(SoberTheme.peach)
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
            
            ZStack {
                Circle()
                    .fill(SoberTheme.peach.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(SoberTheme.peach)
            }
            
            Text("\(contactOrAppName) is locked")
                .font(SoberTheme.headline(22))
                .foregroundColor(.white)
            
            Text("You'll thank yourself tomorrow.")
                .font(SoberTheme.body())
                .foregroundColor(SoberTheme.textSecondary)
            
            Text(lockoutTimeString)
                .font(SoberTheme.mono(48))
                .foregroundColor(SoberTheme.peach)
            
            Text("remaining")
                .font(SoberTheme.caption())
                .foregroundColor(SoberTheme.textSecondary)
            
            Spacer()
            
            Button("Go Back") {
                onResult(false)
            }
            .buttonStyle(SoberSecondaryButtonStyle(color: SoberTheme.peach))
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
            activateLockout()
        }
    }
}
