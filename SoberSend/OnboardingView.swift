import SwiftUI
import StoreKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    @State private var currentStep: Int = 0
    
    var body: some View {
        NavigationStack {
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
                    
                    PaywallView()
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentStep)
            }
            .preferredColorScheme(.dark)
        }
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
            
            Text("We both know why you're here.")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Let's set up your lockdown before you make any decisions you'll regret tomorrow.")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text("Let's do this")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Select Danger Contacts
struct SelectDangerContactsView: View {
    @Binding var currentStep: Int
    @Environment(LockdownManager.self) private var lockdownManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Who's on the list?")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Select the apps or contacts you absolutely cannot be trusted with after 10 PM. (First one is free).")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Grant Screen Time Access") {
                Task {
                    await lockdownManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(lockdownManager.isAuthorized ? .green : .blue)
            .disabled(lockdownManager.isAuthorized)
            
            if lockdownManager.isAuthorized {
                Text("✅ Access Granted")
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Set Schedule
struct SetScheduleView: View {
    @Binding var currentStep: Int
    
    @AppStorage("lockStartHour", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var lockStartHour: Int = 22
    @AppStorage("lockStartMinute", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var lockStartMinute: Int = 0
    @AppStorage("lockEndHour", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var lockEndHour: Int = 7
    @AppStorage("lockEndMinute", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var lockEndMinute: Int = 0
    
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("When are you dangerous?")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Default is 10 PM to 7 AM. Be honest with yourself.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    .onChange(of: startTime) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        lockStartHour = components.hour ?? 22
                        lockStartMinute = components.minute ?? 0
                    }
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        lockEndHour = components.hour ?? 7
                        lockEndMinute = components.minute ?? 0
                    }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .onAppear {
            startTime = Calendar.current.date(bySettingHour: lockStartHour, minute: lockStartMinute, second: 0, of: Date()) ?? Date()
            endTime = Calendar.current.date(bySettingHour: lockEndHour, minute: lockEndMinute, second: 0, of: Date()) ?? Date()
        }
    }
}

// MARK: - Demo Challenge
struct DemoChallengeView: View {
    @Binding var currentStep: Int
    @State private var demoPassed = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("The Vibe Check")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Experience the challenge while you're sober so you know what you're up against later.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text("847 × 13 = ?")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            if demoPassed {
                Text("✅ Passed. You're probably fine.")
                    .foregroundColor(.green)
                    .bold()
            } else {
                Button("Simulate Passing Test") {
                    withAnimation { demoPassed = true }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text(demoPassed ? "Next" : "Skip Demo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Set Intentions
struct SetIntentionsView: View {
    @Binding var currentStep: Int
    @State private var intentionText = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Notes to future you")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Write yourself a sober note. We'll show this to you when you try to unlock an app or contact.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $intentionText)
                .frame(height: 150)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .overlay(
                    Group {
                        if intentionText.isEmpty {
                            Text("e.g., 'You already texted him twice this week. Don't do it.'")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 16)
                                .padding(.leading, 52)
                                .allowsHitTesting(false)
                        }
                    }, alignment: .topLeading
                )
            
            Spacer()
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Unlock Expert Mode")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Free: 1 contact or 1 app, medium difficulty.\nPremium: Unlimited locks, expert challenges, full statistics.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if storeManager.isPremium {
                Text("🎉 Premium Unlocked!")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                ForEach(storeManager.products) { product in
                    Button(action: {
                        Task {
                            try? await storeManager.purchase(product)
                        }
                    }) {
                        VStack {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.displayPrice)
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text(storeManager.isPremium ? "Enter App" : "Continue with Free")
                    .font(.headline)
                    .foregroundColor(storeManager.isPremium ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(storeManager.isPremium ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}
