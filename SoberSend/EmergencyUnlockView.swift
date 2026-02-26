import SwiftUI

struct EmergencyUnlockView: View {
    @Environment(EmergencyUnlockManager.self) private var emergencyManager
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    @State private var isAuthenticating: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("Emergency Unlock")
                    .font(.largeTitle).bold()
                
                Text("This will bypass all locks for exactly 5 minutes. You can only use this once every 24 hours. Face ID is required.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Context note — not a paywall
                Text("⚠️ This is for genuine emergencies only. SoberSend logs all emergency unlocks.")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                Button(action: triggerUnlock) {
                    HStack {
                        if isAuthenticating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "faceid")
                        }
                        Text(isAuthenticating ? "Authenticating..." : "Authenticate & Unlock")
                            .bold()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isAuthenticating)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
