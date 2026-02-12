import Foundation

/// AuthService stub - Firebase Auth integration
/// NOTE: Requires Firebase SDK and GoogleService-Info.plist to be configured.
/// See MVP_Firebase_Setup.md for setup instructions.
///
/// Once Firebase is set up:
/// 1. Import FirebaseAuth
/// 2. Call FirebaseApp.configure() in IppoMVPApp.init
/// 3. Implement Apple Sign-In flow
/// 4. Use auth state to gate CloudService sync

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var displayName: String?
    
    private init() {}
    
    // MARK: - Sign In with Apple (stub)
    func signInWithApple() async throws {
        // TODO: Implement when Firebase is configured
        // 1. Create ASAuthorizationAppleIDRequest
        // 2. Get credential from Apple
        // 3. Create Firebase credential with OAuthProvider
        // 4. Sign in with Firebase Auth
        // 5. Set isAuthenticated, userId, displayName
        
        print("AuthService: Sign In with Apple not yet configured. See MVP_Firebase_Setup.md")
    }
    
    // MARK: - Sign Out
    func signOut() {
        // TODO: Implement when Firebase is configured
        // Auth.auth().signOut()
        isAuthenticated = false
        userId = nil
        displayName = nil
    }
    
    // MARK: - Check Auth State
    func checkAuthState() {
        // TODO: Implement when Firebase is configured
        // Listen for Auth.auth().addStateDidChangeListener
        isAuthenticated = false
    }
}
