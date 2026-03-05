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

                Text("Lv. \(pet.level) · \(pet.stageName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var xpProgress: some View {
        XPProgressBar(
            progress: pet.xpProgress,
            currentXP: pet.experience - pet.xpForCurrentLevel,
            targetXP: max(1, pet.xpForNextLevel - pet.xpForCurrentLevel),
            label: pet.isMaxLevel ? "Max Level" : "Lv. \(pet.level + 1)"
        )
    }

    private var evolutionTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evolution")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 0) {
                ForEach(1...PetConfig.shared.maxStages, id: \.self) { stage in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(stage <= pet.evolutionStage ? AppColors.accent : AppColors.surfaceElevated)
                                .frame(width: stage == pet.evolutionStage ? 28 : 20,
                                       height: stage == pet.evolutionStage ? 28 : 20)
                            if stage <= pet.evolutionStage {
                                Image(systemName: "checkmark")
                                    .font(.system(size: stage == pet.evolutionStage ? 12 : 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(PetConfig.shared.stageName(for: stage))
                            .font(.system(size: 11, weight: stage == pet.evolutionStage ? .semibold : .regular, design: .rounded))
                            .foregroundColor(stage <= pet.evolutionStage ? AppColors.textPrimary : AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    if stage < PetConfig.shared.maxStages {
                        Rectangle()
                            .fill(stage < pet.evolutionStage ? AppColors.accent : AppColors.surfaceElevated)
                            .frame(height: 2)
                            .padding(.bottom, 20)
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
