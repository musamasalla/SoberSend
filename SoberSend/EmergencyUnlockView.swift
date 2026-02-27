import SwiftUI

struct EmergencyUnlockView: View {
    @Environment(EmergencyUnlockManager.self) private var emergencyManager
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    @State private var isAuthenticating: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SoberTheme.background.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer(minLength: 20)
                    
                    ZStack {
                        Circle().fill(SoberTheme.peachCard).frame(width: 120, height: 120)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 56)).foregroundStyle(SoberTheme.peachText)
                    }
                    
                    Text("Emergency Unlock")
                        .font(SoberTheme.title(28)).foregroundStyle(SoberTheme.textPrimary)
                    
                    Text("This will bypass all locks for exactly 5 minutes. You can only use this once every 24 hours. Face ID is required.")
                        .font(SoberTheme.body())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(SoberTheme.textSecondary)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(SoberTheme.peachText)
                        Text("This is for genuine emergencies only. SoberSend logs all emergency unlocks.")
                            .font(SoberTheme.caption()).foregroundStyle(SoberTheme.peachText)
                    }
                    .padding(14)
                    .background(SoberTheme.peachCard, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(SoberTheme.peachText)
                            .font(SoberTheme.body())
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .background(SoberTheme.peachCard.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Button {
                        triggerUnlock()
                    } label: {
                        HStack {
                            if isAuthenticating { ProgressView().tint(.white) }
                            else { Image(systemName: "faceid") }
                            Text(isAuthenticating ? "Authenticating..." : "Authenticate & Unlock")
                        }
                    }
                    .buttonStyle(SoberPrimaryButtonStyle(color: SoberTheme.peachText))
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(SoberTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func triggerUnlock() {
        isAuthenticating = true; errorMessage = nil
        emergencyManager.attemptEmergencyUnlock { success, error in
            isAuthenticating = false
            if success { lockdownManager.activateBypass(duration: 300); dismiss() }
            else { errorMessage = error }
        }
    }
}
