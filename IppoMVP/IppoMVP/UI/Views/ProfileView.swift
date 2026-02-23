import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false

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
                        statRow(label: "Level", value: "\(userData.profile.level)")
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
                            showDeleteConfirm = true
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

                    #if DEBUG
                    Section("Debug") {
                        Button("Load Test Data") {
                            userData.loadTestData()
                        }
                    }
                    .listRowBackground(AppColors.surface)
                    #endif
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
                    dismiss()
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await authService.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("This cannot be undone. All your pets and progress will be lost.")
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

    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}
