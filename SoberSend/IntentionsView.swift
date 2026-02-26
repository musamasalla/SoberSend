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
            ScrollView {
                VStack(spacing: 20) {
                    Text("Heading Out? 🍻")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    Text("Write a note to yourself. We'll show it to you if you try to open these locked apps/contacts.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Fixed TextEditor with proper dark mode styling
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $intentionText)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(height: 120)
                        
                        if intentionText.isEmpty {
                            Text("e.g. \"You already texted him twice this week. Stop.\"")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.body)
                                .padding(.top, 20)
                                .padding(.leading, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Quick-Lock Targets
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Quick-Lock Targets")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        ForEach(contacts) { contact in
                            HStack {
                                Text(contact.displayName)
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { contact.isActive },
                                    set: { newValue in
                                        if !newValue && lockdownManager.isCurrentlyInLockedWindow() {
                                            challengingContact = contact
                                        } else {
                                            contact.isActive = newValue
                                            try? modelContext.save()
                                        }
                                    }
                                ))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            
                            if contact.id != contacts.last?.id {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Button(action: saveIntentions) {
                        Text("Lock It Down 🔒")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Intentions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        // Save globally
        globalSoberNote = intentionText
        // Also save per-contact
        for contact in contacts {
            if !intentionText.isEmpty {
                contact.soberNote = intentionText
            }
        }
        try? modelContext.save()
        dismiss()
    }
}
