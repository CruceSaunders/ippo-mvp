import SwiftUI

/// Admin debug panel -- only accessible to crucesaunders@icloud.com
/// Works in production/TestFlight, not gated by #if DEBUG
struct AdminDebugView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    // Quick add fields
    @State private var rpAmount = ""
    @State private var xpAmount = ""
    @State private var boxCount = ""
    @State private var streakDays = ""
    
    // Simulate run fields
    @State private var runMinutes = ""
    @State private var runDistanceKm = ""
    @State private var runSprintsCompleted = ""
    @State private var runSprintsTotal = ""
    @State private var runRPBoxes = ""
    
    @State private var showingResetConfirm = false
    @State private var feedbackMessage = ""
    @State private var showFeedback = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Quick Add Section
                Section {
                    HStack {
                        TextField("Amount", text: $rpAmount)
                            .keyboardType(.numberPad)
                        Button("Add RP") {
                            if let val = Int(rpAmount), val > 0 {
                                userData.addRP(val)
                                showFeedback("+\(val) RP added")
                                rpAmount = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.brandPrimary)
                        .disabled(Int(rpAmount) == nil)
                    }
                    
                    HStack {
                        TextField("Amount", text: $xpAmount)
                            .keyboardType(.numberPad)
                        Button("Add XP") {
                            if let val = Int(xpAmount), val > 0 {
                                userData.addXP(val)
                                showFeedback("+\(val) XP added")
                                xpAmount = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(Int(xpAmount) == nil)
                    }
                    
                    HStack {
                        TextField("Count", text: $boxCount)
                            .keyboardType(.numberPad)
                        Button("Add Boxes") {
                            if let val = Int(boxCount), val > 0 {
                                userData.addRPBoxes(count: val)
                                showFeedback("+\(val) RP Boxes added")
                                boxCount = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(Int(boxCount) == nil)
                    }
                    
                    HStack {
                        TextField("Days", text: $streakDays)
                            .keyboardType(.numberPad)
                        Button("Set Streak") {
                            if let val = Int(streakDays), val >= 0 {
                                userData.profile.currentStreak = val
                                userData.profile.longestStreak = max(userData.profile.longestStreak, val)
                                userData.save()
                                showFeedback("Streak set to \(val) days")
                                streakDays = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(Int(streakDays) == nil)
                    }
                } header: {
                    Text("Quick Add")
                } footer: {
                    Text("Add resources directly to your account.")
                }
                
                // MARK: - Current Stats
                Section("Current Stats") {
                    statRow("RP", value: "\(userData.profile.rp)")
                    statRow("XP", value: "\(userData.profile.xp)")
                    statRow("Level", value: "\(userData.profile.level)")
                    statRow("Rank", value: userData.profile.rankTier.displayName)
                    statRow("Streak", value: "\(userData.profile.currentStreak) days")
                    statRow("RP Boxes", value: "\(userData.totalRPBoxes)")
                    statRow("Total Runs", value: "\(userData.profile.totalRuns)")
                    statRow("Weekly RP", value: "\(userData.profile.weeklyRP)")
                }
                
                // MARK: - Simulate Run
                Section {
                    TextField("Duration (minutes)", text: $runMinutes)
                        .keyboardType(.numberPad)
                    TextField("Distance (km)", text: $runDistanceKm)
                        .keyboardType(.decimalPad)
                    TextField("Sprints completed", text: $runSprintsCompleted)
                        .keyboardType(.numberPad)
                    TextField("Sprints total", text: $runSprintsTotal)
                        .keyboardType(.numberPad)
                    TextField("RP Boxes earned", text: $runRPBoxes)
                        .keyboardType(.numberPad)
                    
                    Button("Simulate Run") {
                        simulateRun()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brandPrimary)
                    .disabled(!canSimulateRun)
                } header: {
                    Text("Simulate Run")
                } footer: {
                    Text("Creates a run record and triggers all side effects (XP, streak, boxes) as if you actually ran.")
                }
                
                // MARK: - Danger Zone
                Section("Danger Zone") {
                    Button("Reset All Data") {
                        showingResetConfirm = true
                    }
                    .foregroundColor(AppColors.danger)
                }
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset All Data?", isPresented: $showingResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    userData.logout()
                    showFeedback("All data reset")
                }
            } message: {
                Text("This clears all local and cloud data for your account.")
            }
            .overlay(alignment: .bottom) {
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppColors.success.cornerRadius(20))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
            .animation(.spring(response: 0.3), value: showFeedback)
        }
    }
    
    // MARK: - Helpers
    private var canSimulateRun: Bool {
        guard let mins = Int(runMinutes), mins > 0 else { return false }
        return true
    }
    
    private func simulateRun() {
        let minutes = Int(runMinutes) ?? 0
        let distanceKm = Double(runDistanceKm) ?? 0
        let sprintsComp = Int(runSprintsCompleted) ?? 0
        let sprintsTotal = Int(runSprintsTotal) ?? max(sprintsComp, 0)
        let rpBoxes = Int(runRPBoxes) ?? 0
        
        let run = CompletedRun(
            durationSeconds: minutes * 60,
            distanceMeters: distanceKm * 1000,
            sprintsCompleted: sprintsComp,
            sprintsTotal: sprintsTotal,
            rpBoxesEarned: rpBoxes,
            xpEarned: minutes,  // 1 XP per minute
            averageHR: Int.random(in: 140...170),
            totalCalories: Double(minutes) * 8.5
        )
        
        userData.completeRun(run)
        userData.addRPBoxes(count: rpBoxes)
        
        showFeedback("Run simulated: \(minutes) min, \(rpBoxes) boxes")
        
        // Clear fields
        runMinutes = ""
        runDistanceKm = ""
        runSprintsCompleted = ""
        runSprintsTotal = ""
        runRPBoxes = ""
    }
    
    private func showFeedback(_ message: String) {
        feedbackMessage = message
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showFeedback = false
        }
    }
    
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Admin Check Helper
extension AuthService {
    var isAdmin: Bool {
        email?.lowercased() == "crucesaunders@icloud.com"
    }
}

#Preview {
    AdminDebugView()
        .environmentObject(UserData.shared)
}
