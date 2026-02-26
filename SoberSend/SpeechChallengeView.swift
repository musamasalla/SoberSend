import SwiftUI

struct SpeechChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void
    
    @Environment(ChallengeManager.self) private var challengeManager
    
    @State private var targetPhrase = ""
    @State private var attemptsLeft = 3
    @State private var lastHeard: String? = nil
    @State private var showFailState = false
    @State private var failureMessage = ""
    
    // Expanded tongue twister library (10 twisters)
    let tongueTwisters: [(phrase: String, hint: String)] = [
        ("She sells seashells by the seashore", "Focus on the S sounds"),
        ("How much wood would a woodchuck chuck if a woodchuck could chuck wood", "Say it fast and steady"),
        ("Peter Piper picked a peck of pickled peppers", "Don't skip the P's"),
        ("Irish wristwatch, Swiss wristwatch", "The hardest two words in English"),
        ("Red lorry, yellow lorry, red lorry, yellow lorry", "Keep the rhythm even"),
        ("Unique New York, unique New York, you know you need unique New York", "Try not to say 'unique new yark'"),
        ("Toy boat, toy boat, toy boat", "Three words. You'll mess them up."),
        ("Fuzzy Wuzzy was a bear, Fuzzy Wuzzy had no hair", "Say it like you mean it"),
        ("Six slippery snails slid slowly seaward", "All the S's. Every one of them."),
        ("Betty Botter bought some butter but the butter Betty bought was bitter", "The B's will betray you")
    ]
    
    // Funny failure states: what we *heard* vs what we expected
    let failureStates: [(heard: String, commentary: String)] = [
        ("She shelf seahorse by the shore...", "Close. Very close. Also not close."),
        ("How much would a woo-chuck wood...", "A woo-chuck? What's a woo-chuck?"),
        ("Pizza piper — wait, that's not right", "Hungry? Focus."),
        ("Irish wrist... Swiss... ugh", "Even sober people struggle with this one."),
        ("Red lorry yeh lorry red... red thing", "The lorries escaped you."),
        ("Unique New Yark, unique Nu York...", "New York would like a word."),
        ("Toy boa, boy toat... toat?", "Toat is not a word."),
        ("Fuzzy... fuzzy bear no hair fuzzy", "We heard the important parts, at least."),
        ("Six slippery snails slid... slid... sled?", "A sled. In the ocean."),
        ("Betty Butter bought some bitter...", "Betty is concerned.")
    ]
    
    @State private var selectedFailure: (heard: String, commentary: String)? = nil
    @State private var twistedIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Speech Challenge 🎤")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 32)
            
            Text("Read this aloud clearly.")
                .foregroundColor(.gray)
            
            // Attempts indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < attemptsLeft ? Color.blue : Color.red.opacity(0.4))
                        .frame(width: 12, height: 12)
                }
                Text("\(attemptsLeft) attempt\(attemptsLeft == 1 ? "" : "s") left")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // The phrase card
            VStack(spacing: 8) {
                Text(targetPhrase)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                
                Text(tongueTwisters[twistedIndex].hint)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .padding(.horizontal)
            
            // Failure state: what we heard
            if showFailState, let failure = selectedFailure {
                VStack(spacing: 8) {
                    Text("We heard:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\"\(failure.heard)\"")
                        .font(.callout)
                        .italic()
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    Text(failure.commentary)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Live transcription
            if challengeManager.isRecording {
                VStack(spacing: 4) {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(challengeManager.recognizedText.isEmpty ? "..." : challengeManager.recognizedText)
                        .font(.headline)
                        .foregroundColor(.blue)
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
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(pct >= 0.85 ? Color.green : Color.orange)
                                .frame(width: geo.size.width * CGFloat(pct), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    
                    Text("\(Int(pct * 100))% accuracy — need 85%")
                        .font(.caption)
                        .foregroundColor(pct >= 0.85 ? .green : .orange)
                }
            }
            
            Spacer()
            
            // Record / Stop button
            if challengeManager.isRecording {
                Button(action: stopAndCheck) {
                    Label("Stop & Check", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            } else {
                Button(action: startRecording) {
                    Label(
                        challengeManager.isAuthorizedForSpeech ? "Tap to Record" : "Grant Mic Access",
                        systemImage: "mic.fill"
                    )
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        challengeManager.isAuthorizedForSpeech ? Color.blue : Color.gray,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .disabled(!challengeManager.isAuthorizedForSpeech)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            twistedIndex = Int.random(in: 0..<tongueTwisters.count)
            targetPhrase = tongueTwisters[twistedIndex].phrase
            challengeManager.checkSpeechAuthorization()
        }
        .onDisappear {
            if challengeManager.isRecording { challengeManager.stopRecording() }
        }
    }
    
    private func startRecording() {
        showFailState = false
        try? challengeManager.startRecording(targetPhrase: targetPhrase)
    }
    
    private func stopAndCheck() {
        challengeManager.stopRecording()
        
        let score = challengeManager.speechScore
        if score >= 0.85 {
            SoundManager.shared.playSuccess()
            HapticManager.shared.notification(type: .success)
            onComplete(true)
        } else {
            attemptsLeft -= 1
            HapticManager.shared.notification(type: .error)
            SoundManager.shared.playError()
            
            // Show funny failure state
            selectedFailure = failureStates[twistedIndex % failureStates.count]
            withAnimation { showFailState = true }
            
            if attemptsLeft <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete(false)
                }
            } else {
                // Pick new twister
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { showFailState = false }
                    twistedIndex = Int.random(in: 0..<tongueTwisters.count)
                    targetPhrase = tongueTwisters[twistedIndex].phrase
                }
            }
        }
    }
}
