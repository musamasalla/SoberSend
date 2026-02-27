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
                SoberTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Heading Out? 🍻")
                                .font(SoberTheme.title(28))
                                .foregroundStyle(SoberTheme.textPrimary)
                            Text("Write a note to yourself. We'll show it to you if you try to open these locked apps/contacts.")
                                .foregroundStyle(SoberTheme.textSecondary)
                                .font(SoberTheme.body())
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $intentionText)
                                .focused($isFocused)
                                .foregroundStyle(SoberTheme.textPrimary)
                                .font(SoberTheme.body())
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .frame(height: 120)
                            
                            if intentionText.isEmpty {
                                Text("e.g. \"You already texted him twice this week. Stop.\"")
                                    .foregroundStyle(SoberTheme.textSecondary.opacity(0.5))
                                    .font(SoberTheme.body())
                                    .padding(.top, 20).padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(SoberTheme.card, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        .padding(.horizontal)
                        
                        if !contacts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SoberSectionHeader(title: "Quick-Lock Targets", icon: "person.2.fill")
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    ForEach(contacts) { contact in
                                        HStack {
                                            Text(contact.displayName)
                                                .font(SoberTheme.body())
                                                .foregroundStyle(SoberTheme.textPrimary)
                                            Spacer()
                                            Toggle("", isOn: Binding(
                                                get: { contact.isActive },
                                                set: { newValue in
                                                    if !newValue && lockdownManager.isAppBlockingActive() { challengingContact = contact }
                                                    else { contact.isActive = newValue; try? modelContext.save() }
                                                }
                                            ))
                                            .labelsHidden()
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        if contact.id != contacts.last?.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .soberCard(padding: 0)
                            }
                            .padding(.horizontal)
                        }
                        
                        Button { saveIntentions() } label: { Text("Lock It Down 🔒") }
                            .buttonStyle(SoberPrimaryButtonStyle())
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Intentions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(SoberTheme.textSecondary)
                }
            }
            .onTapGesture { isFocused = false }
        }
        .preferredColorScheme(.light)
        .onAppear { intentionText = globalSoberNote }
        .fullScreenCover(item: $challengingContact) { contact in
            ChallengeCoordinatorView(contactOrAppName: contact.displayName, difficulty: contact.difficulty, soberNote: contact.soberNote) { passed in
                if passed { if let ctx = contact.modelContext { contact.isActive = false; try? ctx.save() } }
                challengingContact = nil
            }
        }
    }
    
    private func saveIntentions() {
        globalSoberNote = intentionText
        for contact in contacts { if !intentionText.isEmpty { contact.soberNote = intentionText } }
        try? modelContext.save()
        dismiss()
    }
}
