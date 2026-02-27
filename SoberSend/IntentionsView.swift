import SwiftUI
import SwiftData

struct IntentionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [LockedContact]
    
    @AppStorage("soberNote", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var globalSoberNote: String = ""
    @State private var intentionText: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    @Environment(LockdownManager.self) private var lockdownManager
    @State private var challengingContact: LockedContact? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                SoberTheme.charcoal.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Heading Out? 🍻")
                                .font(SoberTheme.title(28))
                                .foregroundColor(.white)
                            
                            Text("Write a note to yourself. We'll show it to you if you try to open these locked apps/contacts.")
                                .foregroundColor(SoberTheme.textSecondary)
                                .font(SoberTheme.body())
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Text editor
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $intentionText)
                                .focused($isFocused)
                                .foregroundColor(.white)
                                .font(SoberTheme.body())
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .frame(height: 120)
                            
                            if intentionText.isEmpty {
                                Text("e.g. \"You already texted him twice this week. Stop.\"")
                                    .foregroundColor(SoberTheme.textSecondary.opacity(0.5))
                                    .font(SoberTheme.body())
                                    .padding(.top, 20)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(SoberTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SoberTheme.lavender.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Quick-lock targets
                        if !contacts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SoberSectionHeader(title: "Quick-Lock Targets", icon: "person.2.fill", color: SoberTheme.skyBlue)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    ForEach(contacts) { contact in
                                        HStack {
                                            Text(contact.displayName)
                                                .font(SoberTheme.body())
                                                .foregroundColor(.white)
                                            Spacer()
                                            Toggle("", isOn: Binding(
                                                get: { contact.isActive },
                                                set: { newValue in
                                                    if !newValue && lockdownManager.isAppBlockingActive() {
                                                        challengingContact = contact
                                                    } else {
                                                        contact.isActive = newValue
                                                        try? modelContext.save()
                                                    }
                                                }
                                            ))
                                            .toggleStyle(SoberToggleStyle(onColor: SoberTheme.peach))
                                            .labelsHidden()
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        
                                        if contact.id != contacts.last?.id {
                                            Divider()
                                                .background(SoberTheme.border)
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .soberCard(padding: 0)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Save button
                        Button(action: saveIntentions) {
                            Text("Lock It Down 🔒")
                        }
                        .buttonStyle(SoberPrimaryButtonStyle(color: SoberTheme.lavender))
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Intentions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(SoberTheme.textSecondary)
                }
            }
            .onTapGesture { isFocused = false }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            intentionText = globalSoberNote
        }
        .fullScreenCover(item: $challengingContact) { contact in
            ChallengeCoordinatorView(contactOrAppName: contact.displayName, difficulty: contact.difficulty, soberNote: contact.soberNote) { passed in
                if passed {
                    if let ctx = contact.modelContext {
                        contact.isActive = false
                        try? ctx.save()
                    }
                }
                challengingContact = nil
            }
        }
    }
    
    private func saveIntentions() {
        globalSoberNote = intentionText
        for contact in contacts {
            if !intentionText.isEmpty {
                contact.soberNote = intentionText
            }
        }
        try? modelContext.save()
        dismiss()
    }
}
