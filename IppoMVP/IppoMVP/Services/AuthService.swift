import Foundation
import Combine
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var displayName: String?
    @Published var email: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentNonce: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        listenForAuthState()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Listener
    /// Listens for Firebase auth state changes (persists across app launches)
    private func listenForAuthState() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                if let user {
                    self.isAuthenticated = true
                    self.userId = user.uid
                    self.displayName = user.displayName
                    self.email = user.email
                } else {
                    self.isAuthenticated = false
                    self.userId = nil
                    self.displayName = nil
                    self.email = nil
                }
            }
        }
    }
    
    // MARK: - Sign In with Apple
    
    /// Generates a random nonce for Apple Sign-In security
    func startSignInWithApple() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    /// Handles the Apple Sign-In authorization result
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID credentials"
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                let user = authResult.user
                
                // Update display name if provided by Apple (only on first sign-in)
                if let fullName = appleIDCredential.fullName,
                   let givenName = fullName.givenName {
                    let name = [givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
                    if !name.isEmpty && (user.displayName == nil || user.displayName?.isEmpty == true) {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = name
                        try? await changeRequest.commitChanges()
                        self.displayName = name
                    }
                }
                
                self.isAuthenticated = true
                self.userId = user.uid
                self.displayName = user.displayName
                self.email = user.email
                
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            // User cancelled is not an error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            userId = nil
            displayName = nil
            email = nil
            
            // Clear local user data
            UserData.shared.logout()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            // Clear cloud data
            if let uid = userId {
                await CloudService.shared.deleteUserData(uid: uid)
            }
            
            // Delete Firebase auth account
            try await user.delete()
            
            // Clear local data
            UserData.shared.logout()
            
            isAuthenticated = false
            userId = nil
            displayName = nil
            email = nil
        } catch {
            errorMessage = "Delete account failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Crypto Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
