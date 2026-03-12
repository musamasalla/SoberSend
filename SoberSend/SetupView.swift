import SwiftUI
import FamilyControls
import SwiftData
import ContactsUI

struct SetupView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [LockedContact]
    
    @State private var showAppPicker = false
    @State private var showContactPicker = false
    @State private var showPaywall = false
    @State private var showIntentions = false
    @State private var challengingContact: LockedContact? = nil
    @State private var wasManuallyActiveBeforePicker = false
    
    @AppStorage("soberNote", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var soberNote: String = ""
    
    private let freeAppLimit = 1
    private let freeContactLimit = 1
    
    private var isActive: Bool { lockdownManager.isAppBlockingActive() }
    
    var body: some View {
        @Bindable var lm = lockdownManager
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    statusSection
                    lockTargetsSection
                    contactsSection
                    premiumSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(SoberTheme.background.ignoresSafeArea())
            .navigationTitle("SoberSend")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showIntentions = true } label: {
                        ZStack {
                            Circle().fill(SoberTheme.lavenderCard).frame(width: 36, height: 36)
                            Image(systemName: "pencil.line")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SoberTheme.lavenderText)
                        }
                    }
                }
            }
            .familyActivityPicker(isPresented: $showAppPicker, selection: $lm.selectionToDiscourage)
            .onChange(of: showAppPicker) { _, presented in
                if !presented {
                    // Enforce free app limit
                    if !storeManager.isPremium {
                        let appCount = lockdownManager.selectionToDiscourage.applicationTokens.count
                        if appCount > freeAppLimit {
                            let allowed = Set(lockdownManager.selectionToDiscourage.applicationTokens.prefix(freeAppLimit))
                            lockdownManager.selectionToDiscourage.applicationTokens = allowed
                            showPaywall = true
                        }
                    }
                    // Re-activate if it was active before opening picker
                    if wasManuallyActiveBeforePicker {
                        lockdownManager.isManuallyActivated = true
                        wasManuallyActiveBeforePicker = false
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(onSelect: { contact in
                    // Enforce free contact limit
                    if !storeManager.isPremium && contacts.count >= freeContactLimit {
                        showPaywall = true
                    } else {
                        let displayName = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown Contact"
                        let newContact = LockedContact(contactID: contact.identifier, displayName: displayName)
                        modelContext.insert(newContact)
                        try? modelContext.save()
                    }
                })
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showIntentions) { IntentionsView() }
            .fullScreenCover(item: $challengingContact) { contact in
                ChallengeCoordinatorView(
                    contactOrAppName: contact.displayName,
                    difficulty: contact.difficulty,
                    soberNote: contact.soberNote
                ) { passed in
                    if passed { contact.isActive = false; try? modelContext.save() }
                    challengingContact = nil
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        let inSchedule = lockdownManager.isCurrentlyInLockedWindow()
        
        return VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Status", icon: "shield.fill")
            
            VStack(spacing: 0) {
                // Hero area inside card
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isActive ? SoberTheme.mintCard : SoberTheme.peachCard)
                            .frame(width: 72, height: 72)
                        Image(systemName: isActive ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(isActive ? SoberTheme.mintText : SoberTheme.peachText)
                    }
                    
                    Text(isActive ? "You're Protected" : "You're Unprotected")
                        .font(SoberTheme.headline(20))
                        .foregroundStyle(SoberTheme.textPrimary)
                    
                    if inSchedule && !lockdownManager.isManuallyActivated {
                        SoberPill(text: "SCHEDULE ACTIVE", bgColor: SoberTheme.blueCard, fgColor: SoberTheme.blueText, small: true)
                    } else if lockdownManager.isManuallyActivated {
                        SoberPill(text: "MANUALLY ON", bgColor: SoberTheme.mintCard, fgColor: SoberTheme.mintText, small: true)
                    } else {
                        SoberPill(text: "INACTIVE", bgColor: SoberTheme.peachCard, fgColor: SoberTheme.peachText, small: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                Divider().padding(.horizontal, -16)
                
                // Manual override toggle
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(SoberTheme.lavenderText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manual Override")
                            .font(SoberTheme.body())
                            .foregroundStyle(SoberTheme.textPrimary)
                        Text(inSchedule ? "Schedule is also protecting you" : "Turn on protection right now")
                            .font(SoberTheme.caption(11))
                            .foregroundStyle(SoberTheme.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { lockdownManager.isManuallyActivated },
                        set: { val in
                            lockdownManager.isManuallyActivated = val
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.top, 12)
            }
            .soberCard()
        }
    }
    
    // MARK: - Lock Targets
    
    private var lockTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Lock Targets", icon: "target")
            
            VStack(spacing: 0) {
                // Apps row
                Button { handleAppSelection() } label: {
                    SoberRow(
                        icon: "apps.iphone",
                        iconBg: SoberTheme.lavenderCard,
                        iconFg: SoberTheme.lavenderText,
                        title: "Select Apps to Lock",
                        subtitle: storeManager.isPremium ? "Unlimited" : "Free: \(freeAppLimit) max"
                    )
                }
                .buttonStyle(.plain)
                
                Divider().padding(.leading, 52)
                
                // Contacts row
                Button { handleContactSelection() } label: {
                    SoberRow(
                        icon: "person.crop.circle.badge.plus",
                        iconBg: SoberTheme.blueCard,
                        iconFg: SoberTheme.blueText,
                        title: "Add Contact to Lock",
                        subtitle: storeManager.isPremium ? "Unlimited" : "Free: \(freeContactLimit) max"
                    )
                }
                .buttonStyle(.plain)
            }
            .soberCard()
            
            Text("Note: Apple does not allow apps to block contacts directly in iMessage. Locked Contacts tracks who you shouldn't message and requires a challenge before removal.")
                .font(SoberTheme.caption(11))
                .foregroundStyle(SoberTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Contacts List
    
    @ViewBuilder
    private var contactsSection: some View {
        if !contacts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SoberSectionHeader(title: "Locked Contacts", icon: "person.2.fill")
                
                VStack(spacing: 0) {
                    ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                        contactRow(contact)
                        if index < contacts.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .soberCard()
            }
        }
    }
    
    @ViewBuilder
    private func contactRow(_ contact: LockedContact) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SoberTheme.peachCard)
                    .frame(width: 40, height: 40)
                Text(String(contact.displayName.prefix(1)))
                    .font(SoberTheme.headline())
                    .foregroundStyle(SoberTheme.peachText)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(SoberTheme.headline())
                    .foregroundStyle(SoberTheme.textPrimary)
                SoberPill(
                    text: contact.difficulty.rawValue.uppercased(),
                    bgColor: difficultyColor(contact.difficulty).0,
                    fgColor: difficultyColor(contact.difficulty).1,
                    small: true
                )
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive) { removeContact(contact) } label: {
                Label("Remove", systemImage: "trash")
            }
            Menu("Change Difficulty") {
                ForEach(ChallengeDifficulty.allCases, id: \.self) { d in
                    Button(d.rawValue) {
                        if needsPremium(d) { showPaywall = true }
                        else { contact.difficulty = d; try? modelContext.save() }
                    }
                }
            }
        }
    }
    
    // MARK: - Premium Section
    
    @ViewBuilder
    private var premiumSection: some View {
        if !storeManager.isPremium {
            VStack(alignment: .leading, spacing: 12) {
                SoberSectionHeader(title: "Go Premium", icon: "crown.fill")
                
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(SoberTheme.creamCard).frame(width: 40, height: 40)
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SoberTheme.creamText)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Premium")
                                .font(SoberTheme.headline())
                                .foregroundStyle(SoberTheme.textPrimary)
                            Text("Unlimited contacts, all difficulty levels, full stats")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SoberTheme.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .soberCard()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func handleAppSelection() {
        if isActive {
            wasManuallyActiveBeforePicker = lockdownManager.isManuallyActivated
            lockdownManager.isManuallyActivated = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAppPicker = true }
        } else {
            showAppPicker = true
        }
    }
    
    private func handleContactSelection() {
        if !storeManager.isPremium && contacts.count >= freeContactLimit {
            showPaywall = true
        } else {
            showContactPicker = true
        }
    }
    
    private func removeContact(_ contact: LockedContact) {
        if lockdownManager.isAppBlockingActive() { challengingContact = contact }
        else { modelContext.delete(contact); try? modelContext.save() }
    }
    
    private func difficultyColor(_ d: ChallengeDifficulty) -> (Color, Color) {
        switch d {
        case .easy: return (SoberTheme.mintCard, SoberTheme.mintText)
        case .medium: return (SoberTheme.creamCard, SoberTheme.creamText)
        case .hard: return (SoberTheme.peachCard, SoberTheme.peachText)
        case .expert: return (SoberTheme.lavenderCard, SoberTheme.lavenderText)
        }
    }
    
    private func needsPremium(_ d: ChallengeDifficulty) -> Bool {
        !storeManager.isPremium && (d == .hard || d == .expert)
    }
}
