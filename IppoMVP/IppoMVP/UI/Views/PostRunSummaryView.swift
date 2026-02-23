import SwiftUI

struct PostRunSummaryView: View {
    let run: CompletedRun
    let onDismiss: () -> Void
    @EnvironmentObject var userData: UserData
    @State private var showReveal = false
    @State private var revealPhase = 0
    @State private var sparkleOpacity: Double = 0

    private var caughtPetDef: GamePetDefinition? {
        guard let id = run.petCaughtId else { return nil }
        return GameData.pet(byId: id)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Run Complete!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    statsGrid

                    rewardsRow

                    if let pet = userData.equippedPet, let def = pet.definition {
                        petHappySection(def: def, pet: pet)
                    }

                    if let caughtDef = caughtPetDef {
                        petRevealSection(caughtDef)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text(caughtPetDef != nil ? "Meet \(caughtPetDef!.name)" : "Continue")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.accent)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .onAppear {
            if caughtPetDef != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showReveal = true
                    }
                }
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            statItem(value: formatDuration(run.durationSeconds), label: "Duration")
            statItem(value: formatDistance(run.distanceMeters), label: "Distance")
            statItem(value: "\(run.sprintsCompleted)", label: "Sprints")
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    private var rewardsRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.coins)
                Text("+\(run.coinsEarned)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.coins)
            }

            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.xp)
                Text("+\(run.xpEarned)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.xp)
            }
        }
    }

    @ViewBuilder
    private func petHappySection(def: GamePetDefinition, pet: OwnedPet) -> some View {
        VStack(spacing: 8) {
            Image(pet.currentImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)

            Text("\(def.name) is happy you ran together!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    @ViewBuilder
    private func petRevealSection(_ def: GamePetDefinition) -> some View {
        VStack(spacing: 16) {
            Text("...but wait...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .opacity(showReveal ? 0 : 1)

            if showReveal {
                VStack(spacing: 12) {
                    Text("NEW FRIEND CAUGHT!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.accent)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.accentSoft.opacity(0.2))

                        Image(def.stageImageNames.first ?? "pet_placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(24)
                    }
                    .frame(height: 160)

                    Text(def.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    Text(def.description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}
