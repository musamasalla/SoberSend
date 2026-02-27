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
        ZStack {
            FloatingOrbsBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Hero Status Card
                    heroStatusCard
                    
                    // MARK: - Lock Targets
                    lockTargetsSection
                    
                    // MARK: - Locked Contacts
                    if !lockedContacts.isEmpty {
                        lockedContactsSection
                    }
                    
                    // MARK: - Premium Upsell
                    if !storeManager.isPremium {
                        premiumBanner
                    }
                    
                    Spacer(minLength: 100) // Tab bar clearance
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
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
        .sheet(isPresented: $isShowingContactPicker) {
            ContactPickerView().ignoresSafeArea()
        }
    }
    
    // MARK: - Hero Status Card
    
    private var heroStatusCard: some View {
        VStack(spacing: 16) {
            AnimatedLockIcon(isActive: lockdownManager.isAppBlockingActive())
            
            Text(lockdownManager.isAppBlockingActive() ? "Lockdown Active" : "You're Unprotected")
                .font(SoberTheme.headline(20))
                .foregroundColor(lockdownManager.isAppBlockingActive() ? SoberTheme.peach : SoberTheme.mint)
            
            if lockdownManager.isCurrentlyInLockedWindow() {
                SoberPill(text: "SCHEDULED WINDOW", color: SoberTheme.peach, small: true)
            } else if lockdownManager.isManuallyActivated {
                SoberPill(text: "MANUAL LOCK", color: SoberTheme.lavender, small: true)
            } else {
                SoberPill(text: "INACTIVE", color: SoberTheme.mint, small: true)
            }
            
            // Activate toggle
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(SoberTheme.lavender)
                Text("Activate Now")
                    .font(SoberTheme.body())
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: Bindable(lockdownManager).isManuallyActivated)
                    .toggleStyle(SoberToggleStyle(onColor: SoberTheme.peach))
                    .labelsHidden()
            }
            .padding(.top, 4)
        }
        .soberCard(padding: 24, cornerRadius: 24)
    }
    
    // MARK: - Lock Targets Section
    
    private var lockTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Lock Targets", icon: "target", color: SoberTheme.lavender)
            
            // Apps card
            Button(action: { showAppPicker = true }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SoberTheme.lavender.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SoberTheme.lavender)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lockdownManager.selectionToDiscourage.applicationTokens.isEmpty
                             ? "Select Apps to Lock"
                             : "\(lockdownManager.selectionToDiscourage.applicationTokens.count) App\(lockdownManager.selectionToDiscourage.applicationTokens.count == 1 ? "" : "s") Locked")
                            .font(SoberTheme.headline())
                            .foregroundColor(.white)
                        
                        if !storeManager.isPremium {
                            Text("Free: \(freeAppLimit) max")
                                .font(SoberTheme.caption())
                                .foregroundColor(SoberTheme.peach)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(SoberTheme.textSecondary)
                }
                .soberCard()
            }
            .buttonStyle(.plain)
            
            // Contacts card
            Button(action: {
                if !storeManager.isPremium && lockedContacts.count >= freeContactLimit {
                    showPaywall = true
                } else {
                    isShowingContactPicker = true
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SoberTheme.skyBlue.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SoberTheme.skyBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Contact to Lock")
                            .font(SoberTheme.headline())
                            .foregroundColor(.white)
                        
                        if !storeManager.isPremium {
                            Text("Free: \(freeContactLimit) max")
                                .font(SoberTheme.caption())
                                .foregroundColor(SoberTheme.peach)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(SoberTheme.textSecondary)
                }
                .soberCard()
            }
            .buttonStyle(.plain)
            
            // Disclaimer
            Text("Note: Apple does not allow apps to block contacts directly in iMessage. Locked Contacts tracks who you shouldn't message and requires a challenge before removal.")
                .font(SoberTheme.caption(11))
                .foregroundColor(SoberTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Locked Contacts Section
    
    private var lockedContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Locked Contacts", icon: "person.2.fill", color: SoberTheme.skyBlue)
            
            ForEach(lockedContacts) { contact in
                contactRow(contact)
            }
        }
    }
    
    @ViewBuilder
    private func contactRow(_ contact: LockedContact) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(contact.isActive ? SoberTheme.peach.opacity(0.15) : SoberTheme.mint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(contact.displayName.prefix(1)))
                        .font(SoberTheme.headline())
                        .foregroundColor(contact.isActive ? SoberTheme.peach : SoberTheme.mint)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.displayName)
                        .font(SoberTheme.headline())
                        .foregroundColor(.white)
                    difficultyBadge(contact.difficulty)
                }
                
                Spacer()
                
                // Difficulty picker
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
                        .foregroundColor(SoberTheme.textSecondary)
                        .frame(width: 32, height: 32)
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
                .toggleStyle(SoberToggleStyle(onColor: SoberTheme.peach))
                .labelsHidden()
            }
            
            if let note = contact.soberNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundColor(SoberTheme.cream.opacity(0.5))
                    Text(note)
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.cream.opacity(0.7))
                        .italic()
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .soberCard()
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(contact)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SoberTheme.lavender.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("⭐️")
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Premium")
                        .font(SoberTheme.headline())
                        .foregroundColor(SoberTheme.lavender)
                    Text("Unlimited contacts, all difficulty levels, full stats")
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(SoberTheme.lavender.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(SoberTheme.lavender.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(SoberTheme.lavender.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func difficultyBadge(_ diff: ChallengeDifficulty) -> some View {
        SoberPill(text: difficultyLabel(diff), color: difficultyColor(diff), small: true)
    }
    
    private func difficultyLabel(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "Easy"; case .medium: "Medium"; case .hard: "Hard"; case .expert: "Expert 💀" }
    }
    private func difficultyIcon(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "1.circle"; case .medium: "2.circle"; case .hard: "3.circle"; case .expert: "flame" }
    }
    private func difficultyColor(_ diff: ChallengeDifficulty) -> Color {
        switch diff { case .easy: SoberTheme.mint; case .medium: SoberTheme.skyBlue; case .hard: SoberTheme.peach; case .expert: SoberTheme.danger }
    }
}
