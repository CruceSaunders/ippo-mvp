import Foundation
import Combine
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    static let adminUserIds: Set<String> = ["xcBSbYY6lNToyzsxB7m0Jh6dgkZ2"]
    static let adminEmails: Set<String> = ["cruce.saunders@alpha.school", "crucesaunders@icloud.com"]
    
    var isAdmin: Bool {
        if let uid = userId, Self.adminUserIds.contains(uid) { return true }
        if let email = email {
            let lower = email.lowercased()
            if Self.adminEmails.contains(lower) { return true }
            // Apple relay addresses contain the original Apple ID user identifier
            if lower.contains("crucesaunders") { return true }
        }
        if UserDefaults.standard.bool(forKey: "isAdminUser") { return true }
        return false
    }
    
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var displayName: String?
    @Published var email: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentNonce: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var reauthContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var reauthNonce: String?
    private var reauthController: ASAuthorizationController?
    
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
        let hashedNonce = sha256(nonce)
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
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

                // Apple may hide the real email behind a relay address.
                // The credential email is only available on first sign-in,
                // so persist admin status when we see it.
                if let credentialEmail = appleIDCredential.email?.lowercased(),
                   Self.adminEmails.contains(credentialEmail) {
                    UserDefaults.standard.set(true, forKey: "isAdminUser")
                }

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
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Firebase client ID"
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Missing Google ID token"
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            if let displayName = result.user.profile?.name,
               (user.displayName == nil || user.displayName?.isEmpty == true) {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
                self.displayName = displayName
            }
            
            self.isAuthenticated = true
            self.userId = user.uid
            self.displayName = user.displayName
            self.email = user.email
        } catch {
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
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

            UserData.shared.logout()
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "isAdminUser")
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No signed-in user found."])
        }
        let uid = user.uid

        do {
            try await user.delete()
        } catch {
            guard (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue else {
                throw error
            }
            try await reauthenticate(user: user)
            try await user.delete()
        }

        await CloudService.shared.deleteUserData(uid: uid)

        UserData.shared.logout()
        isAuthenticated = false
        userId = nil
        displayName = nil
        email = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "isAdminUser")
    }

    // MARK: - Re-authentication

    private func reauthenticate(user: User) async throws {
        let providerIds = user.providerData.map { $0.providerID }

        if providerIds.contains("apple.com") {
            try await reauthenticateWithApple(user: user)
        } else if providerIds.contains("google.com") {
            try await reauthenticateWithGoogle(user: user)
        } else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to verify identity for this sign-in method."])
        }
    }

    private func reauthenticateWithApple(user: User) async throws {
        let nonce = randomNonceString()
        reauthNonce = nonce
        let hashedNonce = sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        reauthController = controller

        let authorization: ASAuthorization = try await withCheckedThrowingContinuation { continuation in
            self.reauthContinuation = continuation
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = reauthNonce else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple credentials for verification."])
        }

        let oauthCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        try await user.reauthenticate(with: oauthCredential)
        reauthNonce = nil
    }

    private func reauthenticateWithGoogle(user: User) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID."])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot present Google Sign-In."])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token for verification."])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await user.reauthenticate(with: credential)
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

// MARK: - ASAuthorizationControllerDelegate (for re-authentication)
extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            self.reauthContinuation?.resume(returning: authorization)
            self.reauthContinuation = nil
            self.reauthController = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithError error: Error) {
        Task { @MainActor in
            self.reauthContinuation?.resume(throwing: error)
            self.reauthContinuation = nil
            self.reauthController = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
