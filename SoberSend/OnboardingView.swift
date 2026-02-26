import SwiftUI
import StoreKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    @State private var currentStep: Int = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                .font(.headline)
                .bold()
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("🔒")
                .font(.system(size: 80))
            
            Text("We both know\nwhy you're here.")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Let's set up your lockdown before you make any decisions you'll regret tomorrow.")
                .font(.title3)
                .foregroundColor(.gray)
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
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 40)
            
            Text("Select the apps or contacts you can't be trusted with after 10 PM.\n(First one is free).")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: lockdownManager.isAuthorized ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 60))
                    .foregroundColor(lockdownManager.isAuthorized ? .green : .blue)
                
                if lockdownManager.isAuthorized {
                    Text("Screen Time Access Granted ✅")
                        .foregroundColor(.green)
                        .font(.headline)
                } else {
                    Text("We need Screen Time access to block apps and contacts during your lockdown window.")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: {
                    Task { await lockdownManager.requestAuthorization() }
                }) {
                    Text(lockdownManager.isAuthorized ? "Access Granted" : "Grant Screen Time Access")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(lockdownManager.isAuthorized ? Color.green : Color.blue, in: RoundedRectangle(cornerRadius: 16))
                }
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
    
    // Days: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    let dayNames  = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 28) {
            Text("When are you\ndangerous? 🌙")
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Default is 10 PM to 7 AM.\nBe honest with yourself.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Day of week selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Active nights")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        let weekday = i + 1  // Calendar weekday (1=Sun…7=Sat)
                        let isActive = lockdownManager.isDayActive(weekday)
                        let isWeekend = weekday == 6 || weekday == 7
                        
                        Button(action: {
                            lockdownManager.toggleDay(weekday)
                        }) {
                            Text(dayLabels[i])
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 38, height: 38)
                                .background(isActive ? (isWeekend ? Color.orange : Color.blue) : Color.white.opacity(0.08))
                                .foregroundColor(isActive ? .white : .gray)
                                .clipShape(Circle())
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Weekends") { setWeekends() }
                        .font(.caption)
                        .foregroundColor(.orange)
                    Button("Every Night") { lockdownManager.setAllDays(active: true) }
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 30)
            
            // Time pickers
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "moon.fill").foregroundColor(.indigo)
                    DatePicker("Lockdown starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockStartHour = c.hour ?? 22
                            lockdownManager.lockStartMinute = c.minute ?? 0
                        }
                }
                Divider()
                HStack {
                    Image(systemName: "sunrise.fill").foregroundColor(.orange)
                    DatePicker("Lockdown ends", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockEndHour = c.hour ?? 7
                            lockdownManager.lockEndMinute = c.minute ?? 0
                        }
                }
            }
            .padding()
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
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
        // Fri=6, Sat=7 on Calendar (1=Sun)
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(6) // Friday
        lockdownManager.toggleDay(7) // Saturday
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
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 40)
            
            Text("Try this while you're sober.\nImagine doing it at 2 AM after 6 drinks.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            if demoPassed {
                VStack(spacing: 16) {
                    Text("✅")
                        .font(.system(size: 60))
                    Text("You passed. Easy, right?")
                        .font(.title2)
                        .bold()
                    Text("Now imagine doing that after a few drinks. That's the point.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Solve this:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(num1) + \(num2) = ?")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                    
                    TextField("Your answer", text: $userAnswer)
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 60)
                    
                    if showWrong {
                        Text("Nope. Try again.")
                            .foregroundColor(.red)
                            .font(.callout)
                            .bold()
                    }
                    
                    Button(action: checkDemo) {
                        Text("Submit")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userAnswer.isEmpty ? Color.gray : Color.blue, in: RoundedRectangle(cornerRadius: 16))
                    }
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
            withAnimation { demoPassed = true }
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
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 40)
            
            Text("Write yourself a sober note. We'll show this to you when you try to unlock an app or contact.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $intentionText)
                    .focused($isFocused)
                    .foregroundColor(.white)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(height: 160)
                
                if intentionText.isEmpty {
                    Text("e.g., \"You already texted him twice this week. Don't do it.\"")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.body)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
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

// MARK: - Onboarding Paywall Step (wraps the full-screen PaywallView)
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
        // Pass "Continue with Free" directly into the PaywallView so it renders
        // INSIDE the scroll content — above the legal footer and above the TabView dots.
        PaywallView(onContinueWithFree: { finishOnboarding() })
            .environment(storeManager)
            .environment(notificationManager)
            .onChange(of: storeManager.isPremium) { _, isPremium in
                if isPremium { finishOnboarding() }
            }
    }
}
