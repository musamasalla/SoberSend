import SwiftUI
import StoreKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    @State private var currentStep: Int = 0
    
    var body: some View {
        ZStack {
            FloatingOrbsBackground()
            
            TabView(selection: $currentStep) {
                WelcomeView(currentStep: $currentStep)
                    .tag(0)
                
                SelectDangerContactsView(currentStep: $currentStep)
                    .tag(1)
                
                SetScheduleView(currentStep: $currentStep)
                    .tag(2)
                
                DemoChallengeView(currentStep: $currentStep)
                    .tag(3)
                
                SetIntentionsView(currentStep: $currentStep)
                    .tag(4)
                
                OnboardingPaywallStep()
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentStep)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Shared Next Button
struct OnboardingNextButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(SoberPrimaryButtonStyle(color: SoberTheme.lavender))
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @Binding var currentStep: Int
    @State private var showLock = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated lock
            ZStack {
                Circle()
                    .fill(SoberTheme.lavender.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showLock ? 1.0 : 0.8)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(SoberTheme.lavender)
                    .scaleEffect(showLock ? 1.0 : 0.5)
                    .opacity(showLock ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                    showLock = true
                }
            }
            
            Text("We both know\nwhy you're here.")
                .font(SoberTheme.title(34))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("Let's set up your lockdown before you make any decisions you'll regret tomorrow.")
                .font(SoberTheme.body(17))
                .foregroundColor(SoberTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            OnboardingNextButton(title: "Let's do this") {
                withAnimation { currentStep += 1 }
            }
        }
    }
}

// MARK: - Select Danger Contacts
struct SelectDangerContactsView: View {
    @Binding var currentStep: Int
    @Environment(LockdownManager.self) private var lockdownManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Who's on the list? 🫣")
                .font(SoberTheme.title(30))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            Text("Select the apps or contacts you can't be trusted with after 10 PM.\n(First one is free).")
                .foregroundColor(SoberTheme.textSecondary)
                .font(SoberTheme.body())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(lockdownManager.isAuthorized ? SoberTheme.mint.opacity(0.15) : SoberTheme.lavender.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: lockdownManager.isAuthorized ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                        .font(.system(size: 44))
                        .foregroundColor(lockdownManager.isAuthorized ? SoberTheme.mint : SoberTheme.lavender)
                }
                
                if lockdownManager.isAuthorized {
                    Text("Screen Time Access Granted")
                        .foregroundColor(SoberTheme.mint)
                        .font(SoberTheme.headline())
                } else {
                    Text("We need Screen Time access to block apps and contacts during your lockdown window.")
                        .font(SoberTheme.body())
                        .foregroundColor(SoberTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: {
                    Task { await lockdownManager.requestAuthorization() }
                }) {
                    Text(lockdownManager.isAuthorized ? "Access Granted ✓" : "Grant Screen Time Access")
                }
                .buttonStyle(SoberPrimaryButtonStyle(color: lockdownManager.isAuthorized ? SoberTheme.mint : SoberTheme.lavender))
                .disabled(lockdownManager.isAuthorized)
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            OnboardingNextButton(title: "Next") {
                withAnimation { currentStep += 1 }
            }
        }
    }
}

// MARK: - Set Schedule
struct SetScheduleView: View {
    @Binding var currentStep: Int
    @Environment(LockdownManager.self) private var lockdownManager
    
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    
    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 28) {
            Text("When are you\ndangerous? 🌙")
                .font(SoberTheme.title(30))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Default is 10 PM to 7 AM.\nBe honest with yourself.")
                .foregroundColor(SoberTheme.textSecondary)
                .font(SoberTheme.body())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Day selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Active nights")
                    .font(SoberTheme.caption())
                    .foregroundColor(SoberTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        let weekday = i + 1
                        let isActive = lockdownManager.isDayActive(weekday)
                        let isWeekend = weekday == 6 || weekday == 7
                        
                        Button(action: {
                            lockdownManager.toggleDay(weekday)
                        }) {
                            Text(dayLabels[i])
                                .font(SoberTheme.caption(13))
                                .fontWeight(.bold)
                                .frame(width: 38, height: 38)
                                .background(
                                    isActive
                                    ? (isWeekend ? SoberTheme.peach : SoberTheme.lavender)
                                    : SoberTheme.surfaceBright
                                )
                                .foregroundColor(isActive ? SoberTheme.charcoal : SoberTheme.textSecondary)
                                .clipShape(Circle())
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Weekends") { setWeekends() }
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.peach)
                    Button("Every Night") { lockdownManager.setAllDays(active: true) }
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.lavender)
                }
            }
            .soberCard()
            .padding(.horizontal, 30)
            
            // Time pickers
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "moon.fill").foregroundColor(SoberTheme.lavender)
                    DatePicker("Lockdown starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockStartHour = c.hour ?? 22
                            lockdownManager.lockStartMinute = c.minute ?? 0
                        }
                }
                Divider().background(SoberTheme.border)
                HStack {
                    Image(systemName: "sunrise.fill").foregroundColor(SoberTheme.peach)
                    DatePicker("Lockdown ends", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockEndHour = c.hour ?? 7
                            lockdownManager.lockEndMinute = c.minute ?? 0
                        }
                }
            }
            .soberCard()
            .padding(.horizontal, 30)
            
            Spacer()
            
            OnboardingNextButton(title: "Next") {
                withAnimation { currentStep += 1 }
            }
        }
        .onAppear {
            startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
        }
    }
    
    private func setWeekends() {
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(6)
        lockdownManager.toggleDay(7)
    }
}


// MARK: - Demo Challenge (Real Math Problem)
struct DemoChallengeView: View {
    @Binding var currentStep: Int
    @State private var demoPassed = false
    @State private var num1 = Int.random(in: 10...50)
    @State private var num2 = Int.random(in: 10...50)
    @State private var userAnswer = ""
    @State private var showWrong = false
    
    private var correctAnswer: Int { num1 + num2 }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("The Vibe Check 🧠")
                .font(SoberTheme.title(30))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            Text("Try this while you're sober.\nImagine doing it at 2 AM after 6 drinks.")
                .foregroundColor(SoberTheme.textSecondary)
                .font(SoberTheme.body())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            if demoPassed {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(SoberTheme.mint.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(SoberTheme.mint)
                    }
                    Text("You passed. Easy, right?")
                        .font(SoberTheme.headline(20))
                        .foregroundColor(.white)
                    Text("Now imagine doing that after a few drinks. That's the point.")
                        .foregroundColor(SoberTheme.textSecondary)
                        .font(SoberTheme.body())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Solve this:")
                        .font(SoberTheme.headline())
                        .foregroundColor(SoberTheme.textSecondary)
                    
                    Text("\(num1) + \(num2) = ?")
                        .font(SoberTheme.mono(44))
                        .foregroundColor(SoberTheme.lavender)
                    
                    TextField("Your answer", text: $userAnswer)
                        .keyboardType(.numberPad)
                        .font(SoberTheme.mono(28))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                        .background(SoberTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showWrong ? SoberTheme.peach : SoberTheme.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 60)
                    
                    if showWrong {
                        Text("Nope. Try again.")
                            .foregroundColor(SoberTheme.peach)
                            .font(SoberTheme.body())
                            .fontWeight(.semibold)
                    }
                    
                    Button(action: checkDemo) {
                        Text("Submit")
                    }
                    .buttonStyle(SoberPrimaryButtonStyle(color: userAnswer.isEmpty ? SoberTheme.surfaceBright : SoberTheme.lavender))
                    .disabled(userAnswer.isEmpty)
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            OnboardingNextButton(title: demoPassed ? "Next" : "Skip Demo") {
                withAnimation { currentStep += 1 }
            }
        }
    }
    
    private func checkDemo() {
        guard let answer = Int(userAnswer) else { return }
        if answer == correctAnswer {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { demoPassed = true }
            HapticManager.shared.notification(type: .success)
            SoundManager.shared.playSuccess()
        } else {
            showWrong = true
            HapticManager.shared.notification(type: .error)
            SoundManager.shared.playError()
            userAnswer = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showWrong = false
            }
        }
    }
}

// MARK: - Set Intentions
struct SetIntentionsView: View {
    @Binding var currentStep: Int
    @AppStorage("soberNote", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var soberNote: String = ""
    @State private var intentionText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Notes to future you ✍️")
                .font(SoberTheme.title(30))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            Text("Write yourself a sober note. We'll show this to you when you try to unlock an app or contact.")
                .foregroundColor(SoberTheme.textSecondary)
                .font(SoberTheme.body())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $intentionText)
                    .focused($isFocused)
                    .foregroundColor(.white)
                    .font(SoberTheme.body())
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(height: 160)
                
                if intentionText.isEmpty {
                    Text("e.g., \"You already texted him twice this week. Don't do it.\"")
                        .foregroundColor(SoberTheme.textSecondary.opacity(0.5))
                        .font(SoberTheme.body())
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(SoberTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SoberTheme.lavender.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 30)
            
            Spacer()
            
            OnboardingNextButton(title: "Next") {
                soberNote = intentionText
                isFocused = false
                withAnimation { currentStep += 1 }
            }
        }
        .onAppear {
            intentionText = soberNote
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

// MARK: - Onboarding Paywall Step
struct OnboardingPaywallStep: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationManager.self) private var notificationManager
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        Task {
            await notificationManager.requestAuthorization()
            notificationManager.registerNotificationCategories()
            notificationManager.scheduleMorningReport(at: 8, minute: 0)
        }
    }

    var body: some View {
        PaywallView(onContinueWithFree: { finishOnboarding() })
            .environment(storeManager)
            .environment(notificationManager)
            .onChange(of: storeManager.isPremium) { _, isPremium in
                if isPremium { finishOnboarding() }
            }
    }
}
