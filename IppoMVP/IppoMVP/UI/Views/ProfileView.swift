import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteSheet = false
    @State private var showLogoutConfirm = false
    @State private var showEditUsername = false
    @State private var editUsername: String = ""
    @State private var usernameError: String?
    @State private var isCheckingUsername = false
    @State private var showEditDisplayName = false
    @State private var editDisplayName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                List {
                    Section {
                        profileHeader
                    }
                    .listRowBackground(AppColors.surface)

                    Section("Stats") {
                        statRow(label: "Total Runs", value: "\(userData.profile.totalRuns)")
                        statRow(label: "Total Sprints", value: "\(userData.profile.totalSprints)")
                        statRow(label: "Total Distance", value: formatDistance(userData.profile.totalDistanceMeters))
                        statRow(label: "Longest Streak", value: "\(userData.profile.longestStreak) days")
                        statRow(label: "Pets Caught", value: "\(userData.activePets.count)")
                    }
                    .listRowBackground(AppColors.surface)

                    Section("Display Name") {
                        if showEditDisplayName {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Display name", text: $editDisplayName)
                                    .font(.system(size: 16, design: .rounded))
                                    .onChange(of: editDisplayName) { _, newValue in
                                        if editDisplayName.count > 30 { editDisplayName = String(editDisplayName.prefix(30)) }
                                    }

                                HStack {
                                    Button("Cancel") {
                                        showEditDisplayName = false
                                    }
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)

                                    Spacer()

                                    Button("Save") {
                                        let trimmed = editDisplayName.trimmingCharacters(in: .whitespaces)
                                        guard !trimmed.isEmpty else { return }
                                        userData.profile.displayName = trimmed
                                        userData.save()
                                        showEditDisplayName = false
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.accent)
                                    .disabled(editDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                        } else {
                            HStack {
                                Text(userData.profile.displayName)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button("Edit") {
                                    editDisplayName = userData.profile.displayName
                                    showEditDisplayName = true
                                }
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Section("Username") {
                        if showEditUsername {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("@")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.textSecondary)
                                    TextField("username", text: $editUsername)
                                        .font(.system(size: 16, design: .rounded))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .onChange(of: editUsername) { _, newValue in
                                            editUsername = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
                                            if editUsername.count > 20 { editUsername = String(editUsername.prefix(20)) }
                                            usernameError = nil
                                        }
                                }

                                if let error = usernameError {
                                    Text(error)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(AppColors.danger)
                                }

                                HStack {
                                    Button("Cancel") {
                                        showEditUsername = false
                                        usernameError = nil
                                    }
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)

                                    Spacer()

                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }

                                    Button("Save") {
                                        saveUsername()
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.accent)
                                    .disabled(editUsername.count < 3 || isCheckingUsername)
                                }
                            }
                        } else {
                            HStack {
                                Text("@\(userData.profile.username.isEmpty ? "not set" : userData.profile.username)")
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(userData.profile.username.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                                Spacer()
                                Button("Edit") {
                                    editUsername = userData.profile.username
                                    showEditUsername = true
                                }
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Section("Account") {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .foregroundColor(AppColors.warning)
                        }

                        Button {
                            showDeleteSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .foregroundColor(AppColors.danger)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Section {
                        HStack {
                            Spacer()
                            Text("Ippo v3.0")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)

                    if authService.isAdmin {
                        Section("Developer") {
                            NavigationLink("Debug Panel") {
                                AdminDebugView()
                                    .environmentObject(userData)
                                    .environmentObject(authService)
                            }
                        }
                        .listRowBackground(AppColors.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
            .alert("Sign Out?", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            }
            .sheet(isPresented: $showDeleteSheet) {
                DeleteAccountSheet()
                    .environmentObject(userData)
                    .environmentObject(authService)
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.accent)

            Text(userData.profile.displayName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            if !userData.profile.username.isEmpty {
                Text("@\(userData.profile.username)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func saveUsername() {
        let trimmed = editUsername.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            usernameError = "Username must be at least 3 characters"
            return
        }

        if trimmed == userData.profile.username {
            showEditUsername = false
            return
        }

        isCheckingUsername = true
        usernameError = nil

        Task {
            let taken = await CloudService.shared.isUsernameTaken(trimmed)
            if taken {
                usernameError = "That username is already taken"
                isCheckingUsername = false
                return
            }

            let reserved = await CloudService.shared.reserveUsername(trimmed)
            if !reserved {
                usernameError = "Failed to save username. Try again."
                isCheckingUsername = false
                return
            }

            userData.profile.username = trimmed
            userData.save()
            isCheckingUsername = false
            showEditUsername = false
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}

// MARK: - Delete Account Confirmation Sheet
private struct DeleteAccountSheet: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var confirmTarget: String {
        let username = userData.profile.username
        return username.isEmpty ? userData.profile.displayName : username
    }

    private var isConfirmed: Bool {
        confirmText == confirmTarget
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.danger)
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("Delete Your Account?")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("This will permanently delete your account, all your pets, progress, and data. This action cannot be undone.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type **\(confirmTarget)** to confirm")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)

                        TextField("", text: $confirmText)
                            .font(.system(size: 16, design: .rounded))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(AppColors.surface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isConfirmed ? AppColors.danger : AppColors.surfaceElevated, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer()

                    Button {
                        performDeletion()
                    } label: {
                        HStack(spacing: 8) {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Permanently Delete Account")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isConfirmed && !isDeleting ? AppColors.danger : AppColors.danger.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isConfirmed || isDeleting)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                        .disabled(isDeleting)
                }
            }
            .interactiveDismissDisabled(isDeleting)
        }
    }

    private func performDeletion() {
        isDeleting = true
        errorMessage = nil

        Task {
            do {
                try await authService.deleteAccount()
                dismiss()
            } catch {
                let nsError = error as NSError
                if nsError.domain == ASAuthorizationError.errorDomain,
                   nsError.code == ASAuthorizationError.canceled.rawValue {
                    errorMessage = "Identity verification was cancelled. Please try again."
                } else {
                    errorMessage = error.localizedDescription
                }
                isDeleting = false
            }
        }
    }
}
