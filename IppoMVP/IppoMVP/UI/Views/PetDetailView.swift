import SwiftUI

struct PetDetailView: View {
    let pet: OwnedPet
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ParchmentBackground()

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(pet.definition?.name ?? "Pet")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.accent)
                }
            }
        }
    }

    private var petImage: some View {
        ZStack {
            Circle()
                .fill(AppColors.surface)
                .overlay(
                    Circle()
                        .stroke(AppColors.borderBrown, lineWidth: 2)
                )
                .shadow(color: AppColors.parchmentDark.opacity(0.3), radius: 6, y: 2)
                .frame(width: 200, height: 200)

            PetImageView(imageName: pet.currentImageName, size: 160)
                .clipShape(Circle())
                .frame(width: 160, height: 160)

            Circle()
                .stroke(AppColors.vineLight.opacity(0.3), lineWidth: 3)
                .frame(width: 210, height: 210)
        }
        .padding(.top, 16)
    }

    private var petInfo: some View {
        VStack(spacing: 10) {
            Text(pet.definition?.name ?? "Unknown")
                .font(AppTypography.petName)
                .foregroundColor(AppColors.textPrimary)

            Text(pet.definition?.description ?? "")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .italic()

            HStack(spacing: 12) {
                MoodIndicator(mood: pet.mood)

                Text("Lv. \(pet.level) · \(pet.stageName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var xpProgress: some View {
        StoryBookCard {
            VStack(spacing: 8) {
                RibbonBanner(title: "Level \(pet.level) - \(pet.stageName) Stage", style: .small)

                XPProgressBar(
                    progress: pet.xpProgress,
                    currentXP: pet.experience - pet.xpForCurrentLevel,
                    targetXP: max(1, pet.xpForNextLevel - pet.xpForCurrentLevel),
                    label: pet.isMaxLevel ? "Max Level" : "Lv. \(pet.level + 1)"
                )
            }
        }
    }

    private var evolutionTimeline: some View {
        StoryBookCard {
            VStack(spacing: 12) {
                RibbonBanner(title: "Evolution Path", style: .small)

                HStack(spacing: 0) {
                    ForEach(1...PetConfig.shared.maxStages, id: \.self) { stage in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(stage <= pet.evolutionStage
                                          ? LinearGradient(colors: [AppColors.goldLight, AppColors.goldMid], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [AppColors.surfaceDark, AppColors.surfaceDark], startPoint: .top, endPoint: .bottom))
                                    .frame(width: stage == pet.evolutionStage ? 32 : 24,
                                           height: stage == pet.evolutionStage ? 32 : 24)
                                    .overlay(
                                        Circle()
                                            .stroke(stage <= pet.evolutionStage ? AppColors.goldDark : AppColors.borderLight, lineWidth: 1.5)
                                    )

                                if stage <= pet.evolutionStage {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: stage == pet.evolutionStage ? 14 : 10, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }

                            Text(PetConfig.shared.stageName(for: stage))
                                .font(.system(size: 11, weight: stage == pet.evolutionStage ? .semibold : .regular, design: .serif))
                                .foregroundColor(stage <= pet.evolutionStage ? AppColors.textPrimary : AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)

                        if stage < PetConfig.shared.maxStages {
                            Rectangle()
                                .fill(stage < pet.evolutionStage
                                      ? AppColors.goldMid
                                      : AppColors.borderLight)
                                .frame(height: 2)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if !pet.isEquipped {
                GoldButton(
                    title: "Equip \(pet.definition?.name ?? "Pet")",
                    icon: "star.fill",
                    isFullWidth: true,
                    size: .large
                ) {
                    userData.equipPet(pet.id)
                    dismiss()
                }
            } else {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.goldMid)
                    Text("Currently Equipped")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.goldMid)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.goldLight.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.goldMid.opacity(0.4), lineWidth: 1)
                )
            }

            Text("Caught \(pet.caughtDate, style: .date)")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .italic()
        }
    }
}
