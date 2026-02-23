import SwiftUI

struct AdminDebugView: View {
    @EnvironmentObject var userData: UserData
    @State private var feedbackMessage: String?
    @State private var showingResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Actions") {
                    Button("Add 100 Coins") {
                        userData.addCoins(100)
                        showFeedback("+100 coins")
                    }
                    Button("Add 500 XP to Pet") {
                        if let pet = userData.equippedPet,
                           let idx = userData.ownedPets.firstIndex(where: { $0.id == pet.id }) {
                            userData.ownedPets[idx].experience += 500
                            let newStage = PetConfig.shared.currentStage(forXP: userData.ownedPets[idx].experience)
                            userData.ownedPets[idx].evolutionStage = newStage
                            userData.save()
                            showFeedback("+500 XP")
                        }
                    }
                    Button("Add 5 Food + 5 Water") {
                        userData.inventory.food += 5
                        userData.inventory.water += 5
                        userData.save()
                        showFeedback("+5 Food, +5 Water")
                    }
                    Button("Catch Random Pet") {
                        let owned = userData.ownedPetDefinitionIds
                        if let newPet = GameData.shared.randomUnownedPet(ownedPetIds: owned) {
                            userData.addPet(definitionId: newPet.id)
                            showFeedback("Caught \(newPet.name)!")
                        } else {
                            showFeedback("All pets already owned")
                        }
                    }
                    Button("Load Test Data") {
                        userData.loadTestData()
                        showFeedback("Test data loaded")
                    }
                }

                Section("Current State") {
                    statRow("Coins", value: "\(userData.profile.coins)")
                    statRow("Level", value: "\(userData.profile.level)")
                    statRow("XP", value: "\(userData.profile.xp)")
                    statRow("Streak", value: "\(userData.profile.currentStreak)")
                    statRow("Pets Owned", value: "\(userData.activePets.count)")
                    statRow("Food", value: "\(userData.inventory.food)")
                    statRow("Water", value: "\(userData.inventory.water)")
                    if let pet = userData.equippedPet {
                        statRow("Equipped", value: pet.definition?.name ?? "?")
                        statRow("Pet Stage", value: "\(pet.evolutionStage)")
                        statRow("Pet XP", value: "\(pet.experience)")
                        statRow("Pet Mood", value: pet.moodName)
                    }
                }

                Section("Danger Zone") {
                    Button("Reset All Data", role: .destructive) {
                        showingResetConfirm = true
                    }
                }
            }
            .navigationTitle("Debug")
            .overlay {
                if let msg = feedbackMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.success)
                            .cornerRadius(10)
                            .padding(.bottom, 40)
                    }
                }
            }
            .alert("Reset Everything?", isPresented: $showingResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    userData.logout()
                    showFeedback("All data cleared")
                }
            }
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(AppColors.textPrimary)
            Spacer()
            Text(value).foregroundColor(AppColors.textSecondary)
        }
    }

    private func showFeedback(_ msg: String) {
        feedbackMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            feedbackMessage = nil
        }
    }
}
