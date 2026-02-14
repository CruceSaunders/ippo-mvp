import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Logo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.brandPrimary.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: AppColors.brandPrimary.opacity(0.5), radius: 20)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Title
                VStack(spacing: AppSpacing.sm) {
                    Text("Ippo")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Sprint. Earn. Rise.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: AppSpacing.md) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        let appleRequest = authService.startSignInWithApple()
                        request.requestedScopes = appleRequest.requestedScopes
                        request.nonce = appleRequest.nonce
                    } onCompletion: { result in
                        Task {
                            await authService.handleSignInWithApple(result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    // Error message
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    // Loading indicator
                    if authService.isLoading {
                        ProgressView()
                            .tint(AppColors.brandPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                
                // Terms
                Text("By signing in, you agree to our Terms of Service and Privacy Policy.")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
