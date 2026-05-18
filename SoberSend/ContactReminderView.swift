import SwiftUI
import SwiftData

struct ContactReminderView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(ChallengeManager.self) private var challengeManager
    @Environment(EmergencyUnlockManager.self) private var emergencyManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let contact: LockedContact
    
    @State private var showChallenge = false
    @State private var callConfirmed = false
    @State private var soberNoteConfirmed = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SoberTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    // Contact avatar / name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SoberTheme.peachCard)
                                .frame(width: 80, height: 80)
                            Text(String(contact.displayName.prefix(1)))
                                .font(SoberTheme.headline(32))
                                .foregroundStyle(SoberTheme.peachText)
                        }
                        
                        Text(contact.displayName)
                            .font(SoberTheme.headline(24))
                            .foregroundStyle(SoberTheme.textPrimary)
                        
                        Text("is on your reminder list")
                            .font(SoberTheme.body())
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    // Sober note card
                    if let note = contact.soberNote, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 14))
                                    .foregroundStyle(SoberTheme.creamText)
                                Text("Your sober note")
                                    .font(SoberTheme.caption(12).weight(.semibold))
                                    .foregroundStyle(SoberTheme.creamText)
                            }
                            
                            Text("\"\(note)\"")
                                .font(SoberTheme.body().italic())
                                .foregroundStyle(SoberTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(20)
                        .background(SoberTheme.creamCard, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    Spacer().frame(height: 24)
                    
                    // Friction steps
                    VStack(spacing: 16) {
                        // Step 1: Read sober note
                        if let note = contact.soberNote, !note.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: soberNoteConfirmed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(soberNoteConfirmed ? SoberTheme.mintText : SoberTheme.textSecondary)
                                
                                VStack(alignment: .leading) {
                                    Text("Acknowledge your sober note")
                                        .font(SoberTheme.body())
                                        .foregroundStyle(SoberTheme.textPrimary)
                                    Text("Remember why you added this contact")
                                        .font(SoberTheme.caption(12))
                                        .foregroundStyle(SoberTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if !soberNoteConfirmed {
                                Button("Acknowledge") {
                                    withAnimation(.spring()) {
                                        soberNoteConfirmed = true
                                    }
                                }
                                .buttonStyle(SoberPrimaryButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        
                        // Step 2: Call friction
                        if soberNoteConfirmed || contact.soberNote?.isEmpty ?? true {
                            HStack(spacing: 12) {
                                Image(systemName: callConfirmed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(callConfirmed ? SoberTheme.mintText : SoberTheme.textSecondary)
                                
                                VStack(alignment: .leading) {
                                    Text("Complete the challenge to call")
                                        .font(SoberTheme.body())
                                        .foregroundStyle(SoberTheme.textPrimary)
                                    Text("Prove you're in the right headspace")
                                        .font(SoberTheme.caption(12))
                                        .foregroundStyle(SoberTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if !callConfirmed {
                                Button("Take Challenge") {
                                    showChallenge = true
                                }
                                .buttonStyle(SoberSecondaryButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 32)
                    
                    // Call button (only after challenge)
                    if callConfirmed {
                        if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                            Button("Call \(contact.displayName)") {
                                if let url = URL(string:  "tel://\(phoneNumber)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(SoberPrimaryButtonStyle())
                            .padding(.horizontal)
                        } else {
                            Text("No phone number on file for this contact")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Text("SoberSend cannot block calls. This reminder is here to help you pause.")
                            .font(SoberTheme.caption(11))
                            .foregroundStyle(SoberTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(SoberTheme.lavenderText)
                }
            }
        }
        .fullScreenCover(isPresented: $showChallenge) {
            ChallengeCoordinatorView(
                contactOrAppName: contact.displayName,
                difficulty: contact.difficulty,
                soberNote: contact.soberNote
            ) { passed in
                if passed {
                    callConfirmed = true
                }
                showChallenge = false
            }
            .environment(lockdownManager)
            .environment(challengeManager)
            .environment(storeManager)
            .environment(notificationManager)
            .environment(emergencyManager)
        }
    }
}

#Preview {
    ContactReminderView(contact: LockedContact(contactID: "123", displayName: "John Doe", phoneNumber: "+1234567890"))
        .modelContainer(for: LockedContact.self, inMemory: true)
}