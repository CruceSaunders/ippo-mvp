import SwiftUI

struct PetDetailView: View {
    let pet: OwnedPet
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        petImage
                        petInfo
                        xpProgress
                        evolutionTimeline
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(pet.definition?.name ?? "Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
    }

    private var petImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.surface)
            PetImageView(imageName: pet.currentImageName, size: 200)
                .padding(40)
        }
        .frame(height: 250)
    }

    private var petInfo: some View {
        VStack(spacing: 8) {
            Text(pet.definition?.name ?? "Unknown")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(pet.definition?.description ?? "")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                MoodIndicator(mood: pet.mood)

                Text("Stage \(pet.evolutionStage) · \(pet.stageName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var xpProgress: some View {
        XPProgressBar(
            progress: pet.xpProgress,
            currentXP: pet.experience - pet.xpForCurrentStage,
            targetXP: max(1, pet.xpForNextStage - pet.xpForCurrentStage),
            label: pet.isMaxEvolution ? "Max Level" : "to \(PetConfig.shared.stageName(for: pet.evolutionStage + 1))"
        )
    }

    private var evolutionTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evolution Timeline")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 4) {
                ForEach(1...PetConfig.shared.maxStages, id: \.self) { stage in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(stage <= pet.evolutionStage ? AppColors.accent : AppColors.surfaceElevated)
                            .frame(width: stage == pet.evolutionStage ? 16 : 10,
                                   height: stage == pet.evolutionStage ? 16 : 10)
                            .overlay(
                                stage <= pet.evolutionStage
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.white)
                                    : nil
                            )

                        if stage == pet.evolutionStage || stage == 1 || stage == PetConfig.shared.maxStages {
                            Text("\(stage)")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    if stage < PetConfig.shared.maxStages {
                        Rectangle()
                            .fill(stage < pet.evolutionStage ? AppColors.accent : AppColors.surfaceElevated)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if !pet.isEquipped {
                Button {
                    userData.equipPet(pet.id)
                    dismiss()
                } label: {
                    Text("Equip \(pet.definition?.name ?? "Pet")")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent)
                        .cornerRadius(12)
                }
            } else {
                Text("Currently Equipped")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(12)
            }

            HStack(spacing: 16) {
                Text("Caught \(pet.caughtDate, style: .date)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}
