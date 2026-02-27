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

    private let freeContactLimit = 1
    private let freeAppLimit = 1
    private let freeDifficulties: [ChallengeDifficulty] = [.easy, .medium]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                heroStatusCard
                lockTargetsSection
                if !lockedContacts.isEmpty { lockedContactsSection }
                if !storeManager.isPremium { premiumBanner }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(SoberTheme.background.ignoresSafeArea())
        .navigationTitle("SoberSend")
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $isShowingContactPicker) { ContactPickerView().ignoresSafeArea() }
    }
    
    // MARK: - Hero Status Card
    
    private var heroStatusCard: some View {
        PastelAccentCard(bgColor: lockdownManager.isAppBlockingActive() ? SoberTheme.peachCard : SoberTheme.mintCard) {
            VStack(spacing: 14) {
                AnimatedLockIcon(isActive: lockdownManager.isAppBlockingActive())
                
                Text(lockdownManager.isAppBlockingActive() ? "Lockdown Active" : "You're Unprotected")
                    .font(SoberTheme.headline(20))
                    .foregroundStyle(lockdownManager.isAppBlockingActive() ? SoberTheme.peachText : SoberTheme.mintText)
                
                if lockdownManager.isCurrentlyInLockedWindow() {
                    SoberPill(text: "SCHEDULED WINDOW", bgColor: SoberTheme.peachCard, fgColor: SoberTheme.peachText, small: true)
                } else if lockdownManager.isManuallyActivated {
                    SoberPill(text: "MANUAL LOCK", bgColor: SoberTheme.lavenderCard, fgColor: SoberTheme.lavenderText, small: true)
                } else {
                    SoberPill(text: "INACTIVE", bgColor: SoberTheme.mintCard, fgColor: SoberTheme.mintText, small: true)
                }
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(SoberTheme.lavenderText)
                    Text("Activate Now")
                        .font(SoberTheme.body())
                        .foregroundStyle(SoberTheme.textPrimary)
                    Spacer()
                    Toggle("", isOn: Bindable(lockdownManager).isManuallyActivated)
                        .labelsHidden()
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Lock Targets
    
    private var lockTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Lock Targets", icon: "target")
            
            // Apps card
            Button { showAppPicker = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SoberTheme.lavenderCard)
                            .frame(width: 44, height: 44)
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SoberTheme.lavenderText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lockdownManager.selectionToDiscourage.applicationTokens.isEmpty
                             ? "Select Apps to Lock"
                             : "\(lockdownManager.selectionToDiscourage.applicationTokens.count) App\(lockdownManager.selectionToDiscourage.applicationTokens.count == 1 ? "" : "s") Locked")
                            .font(SoberTheme.headline())
                            .foregroundStyle(SoberTheme.textPrimary)
                        if !storeManager.isPremium {
                            Text("Free: \(freeAppLimit) max")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.peachText)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                .soberCard()
            }
            .buttonStyle(.plain)
            
            // Contacts card
            Button {
                if !storeManager.isPremium && lockedContacts.count >= freeContactLimit {
                    showPaywall = true
                } else {
                    isShowingContactPicker = true
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SoberTheme.blueCard)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SoberTheme.blueText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Contact to Lock")
                            .font(SoberTheme.headline())
                            .foregroundStyle(SoberTheme.textPrimary)
                        if !storeManager.isPremium {
                            Text("Free: \(freeContactLimit) max")
                                .font(SoberTheme.caption())
                                .foregroundStyle(SoberTheme.peachText)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(SoberTheme.textSecondary)
                }
                .soberCard()
            }
            .buttonStyle(.plain)
            
            Text("Note: Apple does not allow apps to block contacts directly in iMessage. Locked Contacts tracks who you shouldn't message and requires a challenge before removal.")
                .font(SoberTheme.caption(11))
                .foregroundStyle(SoberTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Locked Contacts
    
    private var lockedContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Locked Contacts", icon: "person.2.fill")
            
            ForEach(lockedContacts) { contact in
                contactRow(contact)
            }
        }
    }
    
    @ViewBuilder
    private func contactRow(_ contact: LockedContact) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(contact.isActive ? SoberTheme.peachCard : SoberTheme.mintCard)
                        .frame(width: 40, height: 40)
                    Text(String(contact.displayName.prefix(1)))
                        .font(SoberTheme.headline())
                        .foregroundStyle(contact.isActive ? SoberTheme.peachText : SoberTheme.mintText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.displayName)
                        .font(SoberTheme.headline())
                        .foregroundStyle(SoberTheme.textPrimary)
                    difficultyBadge(contact.difficulty)
                }
                
                Spacer()
                
                Menu {
                    ForEach(ChallengeDifficulty.allCases, id: \.self) { diff in
                        let isPremiumDiff = !freeDifficulties.contains(diff)
                        Button {
                            if isPremiumDiff && !storeManager.isPremium { showPaywall = true }
                            else { contact.difficulty = diff; try? modelContext.save() }
                        } label: {
                            HStack {
                                Label(difficultyLabel(diff), systemImage: difficultyIcon(diff))
                                if isPremiumDiff && !storeManager.isPremium { Text("⭐️ Premium") }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(SoberTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                
                Toggle("", isOn: Binding(
                    get: { contact.isActive },
                    set: { newValue in
                        if !newValue && lockdownManager.isAppBlockingActive() { challengingContact = contact }
                        else { contact.isActive = newValue; try? modelContext.save() }
                    }
                ))
                .labelsHidden()
            }
            
            if let note = contact.soberNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundStyle(SoberTheme.textSecondary)
                    Text(note)
                        .font(SoberTheme.caption())
                        .foregroundStyle(SoberTheme.textSecondary)
                        .italic()
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .soberCard()
        .contextMenu {
            Button(role: .destructive) { modelContext.delete(contact); try? modelContext.save() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SoberTheme.creamCard)
                        .frame(width: 44, height: 44)
                    Text("⭐️").font(.system(size: 20))
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
                    .font(.caption)
                    .foregroundStyle(SoberTheme.textSecondary)
            }
            .padding(16)
            .background(SoberTheme.creamCard, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func difficultyBadge(_ diff: ChallengeDifficulty) -> some View {
        SoberPill(text: difficultyLabel(diff), bgColor: diffBgColor(diff), fgColor: diffFgColor(diff), small: true)
    }
    private func difficultyLabel(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "Easy"; case .medium: "Medium"; case .hard: "Hard"; case .expert: "Expert 💀" }
    }
    private func difficultyIcon(_ diff: ChallengeDifficulty) -> String {
        switch diff { case .easy: "1.circle"; case .medium: "2.circle"; case .hard: "3.circle"; case .expert: "flame" }
    }
    private func diffBgColor(_ diff: ChallengeDifficulty) -> Color {
        switch diff { case .easy: SoberTheme.mintCard; case .medium: SoberTheme.blueCard; case .hard: SoberTheme.peachCard; case .expert: SoberTheme.peachCard }
    }
    private func diffFgColor(_ diff: ChallengeDifficulty) -> Color {
        switch diff { case .easy: SoberTheme.mintText; case .medium: SoberTheme.blueText; case .hard: SoberTheme.peachText; case .expert: SoberTheme.peachText }
    }
}
