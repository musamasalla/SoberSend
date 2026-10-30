import SwiftUI

struct SpeechChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void
    
    @Environment(ChallengeManager.self) private var challengeManager
    
    @State private var targetPhrase = ""
    @State private var attemptsLeft = 3
    @State private var showFailState = false
    @State private var selectedFailure: (heard: String, commentary: String)? = nil
    @State private var twistedIndex: Int = 0
    @State private var setupError: String? = nil

    // Speech accuracy threshold scales with difficulty
    private var requiredAccuracy: Double {
        switch difficulty {
        case .easy: return 0.80
        case .medium: return 0.85
        case .hard: return 0.90
        case .expert: return 0.93
        }
    }

    // Pick a random twister appropriate for the current difficulty, returning the twister and its original index
    static func pickTwister(for difficulty: ChallengeDifficulty) -> (phrase: String, hint: String, originalIndex: Int) {
        let (minIndex, maxIndex): (Int, Int)
        switch difficulty {
        case .easy: (minIndex, maxIndex) = (0, 2)
        case .medium: (minIndex, maxIndex) = (3, 5)
        case .hard: (minIndex, maxIndex) = (6, 8)
        case .expert: (minIndex, maxIndex) = (9, 12)
        }
        let originalIndex = Int.random(in: minIndex...maxIndex)
        return (SpeechChallengeView.tongueTwisters[originalIndex].phrase,
                SpeechChallengeView.tongueTwisters[originalIndex].hint,
                originalIndex)
    }

    /// Funny failure states: what we *heard* vs what we expected.
    private static var failureStates: [(heard: String, commentary: String)] {
        [
            ("She shelf seahorse by the shore...", "Close. Very close. Also not close."),
            ("Pizza piper — wait, that's not right", "Hungry? Focus."),
            ("Toy boa, boy toat... toat?", "Toat is not a word."),
            ("How much would a woo-chuck wood...", "A woo-chuck? What's a woo-chuck?"),
            ("Red lorry yeh lorry red... red thing", "The lorries escaped you."),
            ("Fuzzy... fuzzy bear no hair fuzzy", "We heard the important parts, at least."),
            ("Irish wrist... Swiss... ugh", "Even sober people struggle with this one."),
            ("Unique New Yark, unique Nu York...", "New York would like a word."),
            ("Six slippery snails slid... slid... sled?", "A sled. In the ocean."),
            ("Betty Butter bought some bitter...", "Betty is concerned."),
            ("The sixth sheikh sheek... sheck...", "Even the sheikh is confused."),
            ("The thrity-three theves...", "They didn't steal your sobriety, just your 'th'."),
            ("Pad kid... poured... card?", "The cod pulled curd? What?")
        ]
    }

    private static var tongueTwisters: [(phrase: String, hint: String)] {
        [
            // Easy (0-2)
            ("She sells seashells by the seashore", "Focus on the S sounds"),
            ("Peter Piper picked a peck of pickled peppers", "Don't skip the P's"),
            ("Toy boat, toy boat, toy boat", "Three words. You'll mess them up."),
            // Medium (3-5)
            ("How much wood would a woodchuck chuck if a woodchuck could chuck wood", "Say it fast and steady"),
            ("Red lorry, yellow lorry, red lorry, yellow lorry", "Keep the rhythm even"),
            ("Fuzzy Wuzzy was a bear, Fuzzy Wuzzy had no hair", "Say it like you mean it"),
            // Hard (6-8)
            ("Irish wristwatch, Swiss wristwatch", "The hardest two words in English"),
            ("Unique New York, unique New York, you know you need unique New York", "Try not to say 'unique new yark'"),
            ("Six slippery snails slid slowly seaward", "All the S's. Every one of them."),
            // Expert (9-12)
            ("Betty Botter bought some butter but the butter Betty bought was bitter", "The B's will betray you"),
            ("The sixth sheikh's sixth sheep's sick, so six sick sheepseeker sheiks seekcher sheeps", "All the SH and S sounds"),
            ("The thirty-three thieves thought that they thrilled the throne throughout Thursday", "Thirty-three thoughts..."),
            ("Pad kid poured curd pulled cod", "The hardest scientific tongue twister in English according to MIT")
        ]
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Speech Challenge 🎤")
                .font(SoberTheme.title())
                .foregroundStyle(SoberTheme.textPrimary)
                .padding(.top, 32)

            Text("Read this aloud clearly.")
                .font(SoberTheme.body())
                .foregroundStyle(SoberTheme.textSecondary)

            // Attempts indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < attemptsLeft ? SoberTheme.mintCard : SoberTheme.peachCard)
                        .frame(width: 12, height: 12)
                }
                Text("\(attemptsLeft) attempt\(attemptsLeft == 1 ? "" : "s") left")
                    .font(SoberTheme.caption())
                    .foregroundStyle(attemptsLeft == 1 ? SoberTheme.peachText : SoberTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(attemptsLeft) attempts remaining")

            // The phrase card
            VStack(spacing: 8) {
                Text(targetPhrase)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(SoberTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)

                Text(Self.tongueTwisters[twistedIndex].hint)
                    .font(SoberTheme.caption())
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            .padding()
            .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            .padding(.horizontal)

            // Failure state: what we heard
            if showFailState, let failure = selectedFailure {
                VStack(spacing: 8) {
                    Text("We heard:")
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                    Text("\"\(failure.heard)\"")
                        .font(.callout)
                        .italic()
                        .foregroundStyle(SoberTheme.peachText)
                        .multilineTextAlignment(.center)
                    Text(failure.commentary)
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                .padding()
                .background(SoberTheme.peachCard, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .transition(.opacity)
            }

            // Setup error (mic denied at the OS level, recognizer unavailable…)
            if let setupError {
                VStack(spacing: 8) {
                    Text(setupError)
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.peachText)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(SoberTheme.caption())
                    .foregroundStyle(SoberTheme.lavenderText)
                }
                .padding()
                .background(SoberTheme.peachCard, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            // Live transcription
            if challengeManager.isRecording {
                VStack(spacing: 4) {
                    Text("Listening...")
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                    Text(challengeManager.recognizedText.isEmpty ? "..." : challengeManager.recognizedText)
                        .font(SoberTheme.headline())
                        .foregroundStyle(SoberTheme.lavenderText)
                        .multilineTextAlignment(.center)
                        .animation(.default, value: challengeManager.recognizedText)
                }
                .padding(.horizontal)
            }

            // Accuracy bar (shown after attempt)
            if !challengeManager.isRecording && challengeManager.speechScore > 0 {
                let pct = min(challengeManager.speechScore, 1.0)
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(SoberTheme.textSecondary.opacity(0.2)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(pct >= requiredAccuracy ? SoberTheme.mintText : SoberTheme.peachText)
                                .frame(width: geo.size.width * CGFloat(pct), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    .accessibilityLabel("Accuracy \(Int(pct * 100)) percent, \(Int(requiredAccuracy * 100)) percent required")

                    Text("\(Int(pct * 100))% accuracy — need \(Int(requiredAccuracy * 100))%")
                        .font(SoberTheme.caption())
                        .foregroundStyle(pct >= requiredAccuracy ? SoberTheme.mintText : SoberTheme.peachText)
                }
            }

            Spacer()

            // Record / Stop button
            if challengeManager.isRecording {
                Button(action: stopAndCheck) {
                    Label("Stop & Check", systemImage: "stop.circle.fill")
                        .font(SoberTheme.headline())
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SoberTheme.peachText, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            } else {
                Button(action: startRecording) {
                    Label(
                        challengeManager.isAuthorizedForSpeech ? "Tap to Record" : "Grant Mic Access",
                        systemImage: "mic.fill"
                    )
                    .font(SoberTheme.headline())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        challengeManager.isAuthorizedForSpeech ? SoberTheme.blueText : SoberTheme.textSecondary,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                // Was permanently disabled when unauthorized, leaving users who
                // denied mic access with no way to complete the challenge.
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SoberTheme.background.ignoresSafeArea())
        .onAppear {
            let (phrase, _, originalIndex) = SpeechChallengeView.pickTwister(for: difficulty)
            twistedIndex = originalIndex
            targetPhrase = phrase
            if !challengeManager.isAuthorizedForSpeech {
                challengeManager.requestSpeechAuthorization()
            }
        }
        .onDisappear {
            if challengeManager.isRecording { challengeManager.stopRecording() }
        }
    }

    private func startRecording() {
        showFailState = false

        // A denied prompt is not permanent — ask again first, and only tell the
        // user to visit Settings once they have actually declined.
        if !challengeManager.isAuthorizedForSpeech {
            challengeManager.requestSpeechAuthorization()
            return
        }

        do {
            try challengeManager.startRecording(targetPhrase: targetPhrase)
            setupError = nil
        } catch {
            // `try?` used to swallow this: tapping Record did nothing at all.
            setupError = error.localizedDescription
        }
    }
    
    private func stopAndCheck() {
        challengeManager.stopRecording()
        
        let score = challengeManager.speechScore
        if score >= requiredAccuracy {
            SoundManager.shared.playSuccess()
            HapticManager.shared.notification(type: .success)
            onComplete(true)
        } else {
            attemptsLeft -= 1
            HapticManager.shared.notification(type: .error)
            SoundManager.shared.playError()
            
            // Show funny failure state
            selectedFailure = SpeechChallengeView.failureStates[twistedIndex % SpeechChallengeView.failureStates.count]
            withAnimation { showFailState = true }
            
            if attemptsLeft <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete(false)
                }
            } else {
                // Pick new twister appropriate for this difficulty
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { showFailState = false }
                    let (phrase, _, originalIndex) = SpeechChallengeView.pickTwister(for: difficulty)
                    twistedIndex = originalIndex
                    targetPhrase = phrase
                }
            }
        }
    }
}
