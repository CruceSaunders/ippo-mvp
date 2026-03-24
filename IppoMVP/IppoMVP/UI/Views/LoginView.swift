import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userData: UserData
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ParchmentBackground()

            VStack(spacing: AppSpacing.xxl) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.surface)
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.borderBrown, lineWidth: 3)
                            )
                            .shadow(color: AppColors.parchmentDark.opacity(0.3), radius: 8, y: 3)

                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                    }

                    Circle()
                        .stroke(AppColors.vineLight.opacity(0.25), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .offset(y: -88)
                        .allowsHitTesting(false)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text("Ippo")
                        .font(.system(size: 46, weight: .bold, design: .serif))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Run. Catch. Grow.")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundColor(AppColors.textSecondary)
                        .italic()
                }

                Spacer()

                VStack(spacing: AppSpacing.md) {
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
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )

                    Button {
                        Task { await authService.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.borderLight, lineWidth: 1)
                        )
                    }

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }

                    if authService.isLoading {
                        ProgressView()
                            .tint(AppColors.accent)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)

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
        .environmentObject(UserData.shared)
}
