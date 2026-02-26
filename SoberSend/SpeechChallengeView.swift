import SwiftUI

struct SpeechChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void
    
    @Environment(ChallengeManager.self) private var challengeManager
    
    @State private var targetPhrase = ""
    @State private var attemptsLeft = 3
    
    let tongueTwisters = [
        "She sells seashells by the seashore",
        "How much wood would a woodchuck chuck if a woodchuck could chuck wood",
        "Peter Piper picked a peck of pickled peppers",
        "Irish wristwatch Swiss wristwatch",
        "Red lorry yellow lorry red lorry yellow lorry"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Speech Challenge")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Read this aloud clearly into the mic.")
                .foregroundColor(.gray)
            
            Text("Attempts left: \(attemptsLeft)")
                .foregroundColor(attemptsLeft == 1 ? .red : .gray)
            
            Spacer()
            
            Text(targetPhrase)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            
            Spacer()
            
            if challengeManager.isRecording {
                Text(challengeManager.recognizedText)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Button(action: { stopAndCheck() }) {
                    Text("Stop Recording")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
            } else {
                Button(action: { startRecording() }) {
                    Text(challengeManager.isAuthorizedForSpeech ? "Hold to Record" : "Grant Mic Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(challengeManager.isAuthorizedForSpeech ? .blue : .gray, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!challengeManager.isAuthorizedForSpeech)
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            targetPhrase = tongueTwisters.randomElement() ?? tongueTwisters[0]
            challengeManager.checkSpeechAuthorization()
        }
        .onDisappear {
            if challengeManager.isRecording {
                challengeManager.stopRecording()
            }
        }
    }
    
    private func startRecording() {
        try? challengeManager.startRecording(targetPhrase: targetPhrase)
    }
    
    private func stopAndCheck() {
        challengeManager.stopRecording()
        
        // Require 85% accuracy (or whatever logic internal returns)
        if challengeManager.speechScore >= 0.85 {
            SoundManager.shared.playSuccess()
            onComplete(true)
        } else {
            attemptsLeft -= 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            SoundManager.shared.playError()
            
            if attemptsLeft <= 0 {
                onComplete(false)
            } else {
                targetPhrase = tongueTwisters.randomElement() ?? tongueTwisters[0]
            }
        }
    }
}
