import SwiftUI
import SwiftData

struct IntentionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [LockedContact]
    
    @State private var intentionText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    @Environment(LockdownManager.self) private var lockdownManager
    @State private var challengingContact: LockedContact? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Heading Out? 🍻")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text("Write a note to yourself. We'll show it to you if you try to open these locked apps/contacts.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $intentionText)
                    .frame(height: 120)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .overlay(
                        Group {
                            if intentionText.isEmpty {
                                Text("e.g. You already texted him twice this week. Stop.")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 16)
                                    .padding(.leading, 24)
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
                
                List {
                    Section("Quick-Lock Targets") {
                        ForEach(contacts) { contact in
                            HStack {
                                Text(contact.displayName)
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
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    Button(action: saveIntentions) {
                        Text("Lock It Down")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .navigationTitle("Intentions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .preferredColorScheme(.dark)
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
    }
    
    private func saveIntentions() {
        for contact in contacts {
            if !intentionText.isEmpty {
                contact.soberNote = intentionText
            }
        }
        try? modelContext.save()
        dismiss()
    }
}
