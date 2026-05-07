import SwiftUI

struct MathChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void
    
    @State private var num1: Int = 0
    @State private var num2: Int = 0
    @State private var operatorSymbol: String = "+"
    @State private var correctAnswer: Int = 0
    @State private var userAnswer: String = ""
    @State private var attemptsLeft = 3
    @State private var showWrong = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Challenge icon
            ZStack {
                Circle()
                    .fill(SoberTheme.lavenderCard)
                    .frame(width: 80, height: 80)
                Image(systemName: "function")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(SoberTheme.lavenderText)
            }
            
            Text("Math Challenge")
                .font(SoberTheme.title(28))
                .foregroundStyle(SoberTheme.textPrimary)
            
            // Attempts indicator
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < attemptsLeft ? SoberTheme.mintCard : SoberTheme.peachCard)
                        .frame(width: 10, height: 10)
                }
                Text("\(attemptsLeft) left")
                    .font(SoberTheme.caption(11))
                    .foregroundStyle(attemptsLeft == 1 ? SoberTheme.peachText : SoberTheme.textSecondary)
            }
            
            Spacer()
            
            // Math problem display
            VStack(spacing: 16) {
                Text("\(num1) \(operatorSymbol) \(num2) = ?")
                    .font(SoberTheme.mono(40))
                    .foregroundStyle(SoberTheme.lavenderText)
                
                TextField("Your answer", text: $userAnswer)
                    .keyboardType(.numberPad)
                    .font(SoberTheme.mono(28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SoberTheme.textPrimary)
                    .padding()
                    .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: showWrong ? SoberTheme.peachCard : .black.opacity(0.06), radius: 8)
                    .padding(.horizontal, 40)
                
                if showWrong {
                    Text("Wrong answer. Try again.")
                        .font(SoberTheme.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(SoberTheme.peachText)
                }
            }
            
            Spacer()
            
            Button(action: checkAnswer) {
                Text("Submit")
            }
            .buttonStyle(SoberPrimaryButtonStyle(color: userAnswer.isEmpty ? .gray.opacity(0.3) : SoberTheme.ctaBlack))
            .disabled(userAnswer.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear(perform: generateProblem)
    }
    
    private func generateProblem() {
        switch difficulty {
        case .easy:
            num1 = Int.random(in: 10...99)
            num2 = Int.random(in: 10...99)
            operatorSymbol = "+"
            correctAnswer = num1 + num2
        case .medium:
            num1 = Int.random(in: 100...999)
            num2 = Int.random(in: 2...9)
            operatorSymbol = "×"
            correctAnswer = num1 * num2
        case .hard:
            num1 = Int.random(in: 100...999)
            num2 = Int.random(in: 11...99)
            operatorSymbol = "×"
            correctAnswer = num1 * num2
        case .expert:
            num1 = Int.random(in: 1000...9999)
            num2 = Int.random(in: 11...99)
            operatorSymbol = "×"
            correctAnswer = num1 * num2
        }
        userAnswer = ""
    }
    
    private func checkAnswer() {
        guard let answer = Int(userAnswer) else { return }
        
        if answer == correctAnswer {
            HapticManager.shared.notification(type: .success)
            SoundManager.shared.playSuccess()
            onComplete(true)
        } else {
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                HapticManager.shared.notification(type: .error)
                onComplete(false)
            } else {
                HapticManager.shared.notification(type: .error)
                SoundManager.shared.playError()
                showWrong = true
                userAnswer = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showWrong = false }
                generateProblem()
            }
        }
    }
}
