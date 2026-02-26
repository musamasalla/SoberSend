import SwiftUI
import SwiftData
import FamilyControls

struct SetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lockedContacts: [LockedContact]
    
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var isShowingContactPicker = false
    @Binding var showAppPicker: Bool
    @State private var challengingContact: LockedContact? = nil
    @State private var showPaywall = false

    // Free tier limits
    private let freeContactLimit = 1
    private let freeAppLimit = 1
    private let freeDifficulties: [ChallengeDifficulty] = [.easy, .medium]

    var body: some View {
        List {
            // Status
            Section {
                HStack {
                    Image(systemName: lockdownManager.isAppBlockingActive() ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(lockdownManager.isAppBlockingActive() ? .red : .green)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(lockdownManager.isAppBlockingActive() ? "Lockdown Active 🔒" : "Lockdown Inactive")
                            .font(.headline)
                            .foregroundColor(lockdownManager.isAppBlockingActive() ? .red : .green)
                        if lockdownManager.isCurrentlyInLockedWindow() {
                            Text("Scheduled window active")
                                .font(.caption).foregroundColor(.gray)
                        } else if lockdownManager.isManuallyActivated {
                            Text("Manually activated")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                
                Toggle(isOn: Bindable(lockdownManager).isManuallyActivated) {
                    Label("Activate Now", systemImage: "bolt.fill")
                }
            } header: { Text("Status") }
            
            // Lock Targets
            Section {
                // Apps — always open the picker (it replaces the full selection).
                // Free tier limit is enforced after selection via onChange.
                Button(action: {
                    showAppPicker = true
                }) {
                    HStack {
                        Label(
                            lockdownManager.selectionToDiscourage.applicationTokens.isEmpty
                                ? "Select Apps to Lock"
                                : "\(lockdownManager.selectionToDiscourage.applicationTokens.count) Apps Locked",
                            systemImage: "apps.iphone"
                        )
                        if !storeManager.isPremium {
                            Spacer()
                            Text("Free: \(freeAppLimit) max")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .foregroundColor(.white)
                
                // Contacts
                Button(action: {
                    if !storeManager.isPremium && lockedContacts.count >= freeContactLimit {
                        showPaywall = true
                    } else {
                        isShowingContactPicker = true
                    }
                }) {
                    HStack {
                        Label("Add Contact to Lock", systemImage: "person.crop.circle.badge.plus")
                        if !storeManager.isPremium {
                            Spacer()
                            Text("Free: \(freeContactLimit) max")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .foregroundColor(.white)
                .sheet(isPresented: $isShowingContactPicker) {
                    ContactPickerView().ignoresSafeArea()
                }
            } header: { Text("Lock Targets") } footer: {
                Text("Note: Apple does not allow apps to block contacts directly in iMessage. Locked Contacts tracks who you shouldn't message and requires a challenge before you can remove them.")
            }
            
            // Locked Contacts with difficulty picker
            if !lockedContacts.isEmpty {
                Section("Locked Contacts") {
                    ForEach(lockedContacts) { contact in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.displayName).font(.headline)
                                    difficultyBadge(contact.difficulty)
                                }
                                Spacer()
                                // Difficulty picker — Hard/Expert locked behind premium
                                Menu {
                                    ForEach(ChallengeDifficulty.allCases, id: \.self) { diff in
                                        let isPremiumDiff = !freeDifficulties.contains(diff)
                                        Button(action: {
                                            if isPremiumDiff && !storeManager.isPremium {
                                                showPaywall = true
                                            } else {
                                                contact.difficulty = diff
                                                try? modelContext.save()
                                            }
                                        }) {
                                            HStack {
                                                Label(difficultyLabel(diff), systemImage: difficultyIcon(diff))
                                                if isPremiumDiff && !storeManager.isPremium {
                                                    Text("⭐️ Premium")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(.gray)
                                }
                                
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
                            }
                            
                            if let note = contact.soberNote, !note.isEmpty {
                                HStack {
                                    Text("📝 \"\(note)\"")
                                        .font(.caption)
                                        .foregroundColor(.yellow.opacity(0.7))
                                        .italic()
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(contact)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Premium upsell banner for free users
            if !storeManager.isPremium {
                Section {
                    Button(action: { showPaywall = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⭐️ Unlock Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Unlimited contacts, all difficulty levels, full stats")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color.blue.opacity(0.15))
                }
            }
        }
        .fullScreenCover(item: $challengingContact) { contact in
            ChallengeCoordinatorView(
                contactOrAppName: contact.displayName,
                difficulty: contact.difficulty,
                soberNote: contact.soberNote
            ) { passed in
                if passed, let ctx = contact.modelContext {
                    contact.isActive = false
                    try? ctx.save()
                }
                challengingContact = nil
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    @ViewBuilder
    private func difficultyBadge(_ diff: ChallengeDifficulty) -> some View {
        Text(difficultyLabel(diff))
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(difficultyColor(diff).opacity(0.2), in: Capsule())
            .foregroundColor(difficultyColor(diff))
    }
    
    private func difficultyLabel(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "Easy"; case .medium: "Medium"; case .hard: "Hard"; case .expert: "Expert 💀" }
    }
    private func difficultyIcon(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "1.circle"; case .medium: "2.circle"; case .hard: "3.circle"; case .expert: "flame" }
    }
    private func difficultyColor(_ diff: ChallengeDifficulty) -> Color {
        switch diff { case .easy: .green; case .medium: .blue; case .hard: .orange; case .expert: .red }
    }
}
