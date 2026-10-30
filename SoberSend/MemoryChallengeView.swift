import SwiftUI

struct MemoryChallengeView: View {
    let difficulty: ChallengeDifficulty
    let onComplete: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The sequence is stored as indices into `colorOptions`, not as `Color`
    /// values. `Color` equality is not reliable across color spaces, so the
    /// original `userSequence[i] != sequence[i]` comparison was fragile.
    @State private var sequence: [Int] = []
    @State private var userSequence: [Int] = []
    @State private var isShowingSequence = true
    @State private var attemptsLeft = 3

    let colorOptions: [(name: String, color: Color)] = [
        ("Red", .red),
        ("Blue", .blue),
        ("Green", .green),
        ("Yellow", .yellow),
        ("Purple", .purple),
        ("Orange", .orange)
    ]

    private var sequenceLength: Int {
        switch difficulty {
        case .easy: return 4
        case .medium: return 5
        case .hard: return 7
        case .expert: return 8
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Memory Challenge")
                .font(SoberTheme.title())
                .foregroundStyle(SoberTheme.textPrimary)
                .padding(.top, 40)

            Text(isShowingSequence ? "Memorize the sequence..." : "Repeat the sequence")
                .font(SoberTheme.body())
                .foregroundStyle(SoberTheme.textSecondary)

            Text("Attempts left: \(attemptsLeft)")
                .font(SoberTheme.caption())
                .foregroundStyle(attemptsLeft == 1 ? SoberTheme.peachText : SoberTheme.textSecondary)
                .accessibilityLabel("\(attemptsLeft) attempts remaining")

            Spacer()

            // Sequence Display
            HStack(spacing: 15) {
                ForEach(0..<sequence.count, id: \.self) { index in
                    let shownIndex = isShowingSequence
                        ? sequence[index]
                        : (index < userSequence.count ? userSequence[index] : nil)
                    Circle()
                        .fill(shownIndex.map { colorOptions[$0].color } ?? SoberTheme.textSecondary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .accessibilityLabel(shownIndex.map { colorOptions[$0].name } ?? "Not entered yet")
                }
            }
            .padding()
            .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

            Spacer()

            // User Input Grid
            if !isShowingSequence {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(0..<colorOptions.count, id: \.self) { index in
                        Button {
                            addToSequence(index)
                        } label: {
                            Circle()
                                .fill(colorOptions[index].color)
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(colorOptions[index].name)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SoberTheme.background.ignoresSafeArea())
        .onAppear(perform: startChallenge)
    }

    private func startChallenge() {
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<colorOptions.count) }
        userSequence = []
        isShowingSequence = true

        // The sequence was visual-only, which made this challenge impossible
        // for VoiceOver users — an unblockable dead end in the middle of the
        // unlock flow. Announce it so the colours can be memorised by ear.
        let spoken = sequence.map { colorOptions[$0].name }.joined(separator: ", ")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AccessibilityNotification.Announcement("Memorize the sequence: \(spoken)").post()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(reduceMotion ? nil : .default) {
                isShowingSequence = false
            }
        }
    }

    private func addToSequence(_ index: Int) {
        guard !isShowingSequence else { return }

        HapticManager.shared.impact(style: .medium)
        SoundManager.shared.playTap()

        userSequence.append(index)

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
