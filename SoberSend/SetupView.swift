import SwiftUI
import SwiftData
import FamilyControls

struct SetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lockedContacts: [LockedContact]
    
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var isShowingFamilyControlsPicker = false
    @State private var isShowingContactPicker = false
    
    @Binding var showAppPicker: Bool
    
    @State private var challengingContact: LockedContact? = nil

    var body: some View {
        List {
            Section {
                Text("Select the apps or contacts to lock.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button(action: {
                    showAppPicker = true
                }) {
                    HStack {
                        Image(systemName: "apps.iphone")
                        Text(lockdownManager.selectionToDiscourage.applicationTokens.isEmpty ? "Select Apps to Lock" : "\(lockdownManager.selectionToDiscourage.applicationTokens.count) Apps Locked")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.white)
                
                Button(action: {
                    isShowingContactPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Add Contact to Lock")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.white)
                .sheet(isPresented: $isShowingContactPicker) {
                    ContactPickerView()
                        .ignoresSafeArea()
                }
            } header: {
                Text("Lock Targets")
            }
            
            if !lockedContacts.isEmpty {
                Section("Locked Contacts") {
                    ForEach(lockedContacts) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.displayName)
                                    .font(.headline)
                                Text("Difficulty: \(contact.difficulty.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { contact.isActive },
                                set: { newValue in
                                    if !newValue && lockdownManager.isCurrentlyInLockedWindow() {
                                        // User is trying to disable a locked contact during lockdown
                                        challengingContact = contact
                                    } else {
                                        contact.isActive = newValue
                                        try? modelContext.save()
                                    }
                                }
                            ))
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
        }
        .fullScreenCover(item: $challengingContact) { contact in
            ChallengeCoordinatorView(contactOrAppName: contact.displayName, difficulty: contact.difficulty, soberNote: contact.soberNote) { passed in
                if passed {
                    // Update state and save
                    if let ctx = contact.modelContext {
                        contact.isActive = false
                        try? ctx.save()
                    }
                }
                // Dismiss cover
                challengingContact = nil
            }
        }
    }
    
    private func deleteContacts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(lockedContacts[index])
            }
        }
    }
}
