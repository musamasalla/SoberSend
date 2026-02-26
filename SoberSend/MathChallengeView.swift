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
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Math Challenge")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Attempts left: \(attemptsLeft)")
                .foregroundColor(attemptsLeft == 1 ? .red : .gray)
            
            Spacer()
            
            HStack {
                Text("\(num1) \(operatorSymbol) \(num2) = ")
                TextField("?", text: $userAnswer)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
            }
            .font(.system(size: 40, weight: .bold, design: .monospaced))
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            Button(action: checkAnswer) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .disabled(userAnswer.isEmpty)
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
        case .hard, .expert:
            num1 = Int.random(in: 100...999)
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
                onComplete(false)
            } else {
                HapticManager.shared.notification(type: .error)
                SoundManager.shared.playError()
                generateProblem() // Make it slightly harder/new numbers
            }
        }
    }
}
