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
                SoberTheme.charcoal.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer(minLength: 20)
                    
                    // Warning icon with peach glow
                    ZStack {
                        Circle()
                            .fill(SoberTheme.peach.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(SoberTheme.peach)
                    }
                    
                    Text("Emergency Unlock")
                        .font(SoberTheme.title(28))
                        .foregroundColor(.white)
                    
                    Text("This will bypass all locks for exactly 5 minutes. You can only use this once every 24 hours. Face ID is required.")
                        .font(SoberTheme.body())
                        .multilineTextAlignment(.center)
                        .foregroundColor(SoberTheme.textSecondary)
                        .padding(.horizontal, 24)
                    
                    // Warning card
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(SoberTheme.peach)
                        Text("This is for genuine emergencies only. SoberSend logs all emergency unlocks.")
                            .font(SoberTheme.caption())
                            .foregroundColor(SoberTheme.peach.opacity(0.8))
                    }
                    .soberCard(padding: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(SoberTheme.peach.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(SoberTheme.peach)
                            .font(SoberTheme.body())
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .background(SoberTheme.peach.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Button(action: triggerUnlock) {
                        HStack {
                            if isAuthenticating {
                                ProgressView().tint(SoberTheme.charcoal)
                            } else {
                                Image(systemName: "faceid")
                            }
                            Text(isAuthenticating ? "Authenticating..." : "Authenticate & Unlock")
                        }
                    }
                    .buttonStyle(SoberPrimaryButtonStyle(color: SoberTheme.peach))
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(SoberTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func triggerUnlock() {
        isAuthenticating = true
        errorMessage = nil
        
        emergencyManager.attemptEmergencyUnlock { success, error in
            isAuthenticating = false
            if success {
                lockdownManager.activateBypass(duration: 300)
                dismiss()
            } else {
                errorMessage = error
            }
        }
    }
}
