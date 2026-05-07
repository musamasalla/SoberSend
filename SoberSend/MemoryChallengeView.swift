import SwiftUI

struct MemoryChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void
    
    @State private var sequence: [Color] = []
    @State private var userSequence: [Color] = []
    @State private var isShowingSequence = true
    @State private var attemptsLeft = 3
    
    let availableColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Memory Challenge")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text(isShowingSequence ? "Memorize the sequence..." : "Repeat the sequence")
                .foregroundColor(.gray)
            
            Text("Attempts left: \(attemptsLeft)")
                .foregroundColor(attemptsLeft == 1 ? .red : .gray)
            
            Spacer()
            
            // Sequence Display
            HStack(spacing: 15) {
                let displayCount = sequence.count
                ForEach(0..<displayCount, id: \.self) { index in
                    Circle()
                        .fill(isShowingSequence ? sequence[index] : (index < userSequence.count ? userSequence[index] : Color.gray.opacity(0.3)))
                        .frame(width: 40, height: 40)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            // User Input Grid
            if !isShowingSequence {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            addToSequence(color)
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear(perform: startChallenge)
    }
    
    private func startChallenge() {
        let count: Int
        switch difficulty {
        case .easy: count = 4
        case .medium: count = 5
        case .hard: count = 7
        case .expert: count = 9
        }
        
        sequence = (0..<count).map { _ in availableColors.randomElement()! }
        userSequence = []
        isShowingSequence = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                isShowingSequence = false
            }
        }
    }
    
    private func addToSequence(_ color: Color) {
        guard !isShowingSequence else { return }
        
        HapticManager.shared.impact(style: .medium)
        SoundManager.shared.playTap()
        
        userSequence.append(color)
        
        let currentIndex = userSequence.count - 1
        
        if userSequence[currentIndex] != sequence[currentIndex] {
            // Wrong move
            HapticManager.shared.notification(type: .error)
            SoundManager.shared.playError()
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                onComplete(false)
            } else {
                startChallenge()
            }
        } else if userSequence.count == sequence.count {
            // Success
            HapticManager.shared.notification(type: .success)
            SoundManager.shared.playSuccess()
            onComplete(true)
        }
    }
}
