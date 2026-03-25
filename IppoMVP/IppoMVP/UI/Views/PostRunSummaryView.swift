import SwiftUI

struct PostRunSummaryView: View {
    let run: CompletedRun
    let onDismiss: () -> Void
    @EnvironmentObject var userData: UserData
    @State private var showReveal = false

    private var newCatches: [GamePetDefinition] {
        run.newPetIds.compactMap { GameData.pet(byId: $0) }
    }

    private var duplicateEncounters: [(def: GamePetDefinition, xp: Int)] {
        run.duplicateEncounters.compactMap { enc in
            guard let def = GameData.pet(byId: enc.petId) else { return nil }
            return (def, enc.bonusXP)
        }
    }

    var body: some View {
        ZStack {
            ParchmentBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Run Complete!")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 12)

                    statsGrid

                    rewardsSection

                    if let pet = userData.equippedPet, let def = pet.definition {
                        petHappySection(def: def, pet: pet)
                    }

                    if !duplicateEncounters.isEmpty {
                        duplicateEncounterSection
                    }

                    if !newCatches.isEmpty {
                        newCatchSection
                    }

                    GoldButton(
                        title: newCatches.first.map { "Meet \($0.name)" } ?? "Continue",
                        icon: !newCatches.isEmpty ? "sparkles" : "arrow.right",
                        isFullWidth: true,
                        size: .large
                    ) {
                        onDismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .onAppear {
            if !newCatches.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    SoundManager.shared.play(.petCatch)
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showReveal = true
                    }
                }
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statItem(value: formatDuration(run.durationSeconds), label: "Duration", icon: "clock")
            statItem(value: formatDistance(run.distanceMeters), label: "Distance", icon: "figure.walk")
            statItem(value: "\(run.sprintsCompleted)", label: "Sprints", icon: "bolt.fill")
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        StoryBookCard(padding: 12) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.borderBrown)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var rewardsSection: some View {
        StoryBookCard {
            VStack(spacing: 8) {
                RibbonBanner(title: "Rewards Earned", style: .small)

                HStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.coins)
                        Text("+\(run.coinsEarned)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.coins)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.xp)
                        Text("+\(run.xpEarned)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.xp)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func petHappySection(def: GamePetDefinition, pet: OwnedPet) -> some View {
        StoryBookCard {
            VStack(spacing: 8) {
                PetImageView(imageName: pet.currentImageName, size: 80)
                    .frame(height: 80)

                Text("\(def.name) is happy you ran together!")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Duplicate Encounters

    private var duplicateEncounterSection: some View {
        VStack(spacing: 12) {
            ForEach(duplicateEncounters, id: \.def.id) { item in
                duplicateEncounterCard(def: item.def, bonusXP: item.xp)
            }
        }
    }

    private func duplicateEncounterCard(def: GamePetDefinition, bonusXP: Int) -> some View {
        StoryBookCard {
            HStack(spacing: 14) {
                ownedPetImage(for: def)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spotted \(def.name)!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.xp)
                        Text("+\(bonusXP) XP to \(def.name)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.xp)
                    }
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func ownedPetImage(for def: GamePetDefinition) -> some View {
        if let owned = userData.ownedPets.first(where: { $0.petDefinitionId == def.id }) {
            PetImageView(imageName: owned.currentImageName, size: 56)
        } else {
            PetImageView(imageName: def.stageImageNames.first ?? "pet_placeholder", size: 56)
        }
    }

    // MARK: - New Catch Reveal

    @ViewBuilder
    private var newCatchSection: some View {
        VStack(spacing: 16) {
            Text("...but wait...")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(AppColors.textSecondary)
                .italic()
                .opacity(showReveal ? 0 : 1)

            if showReveal {
                ForEach(newCatches) { def in
                    newCatchCard(def)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func newCatchCard(_ def: GamePetDefinition) -> some View {
        StoryBookCard(isHighlighted: true) {
            VStack(spacing: 12) {
                RibbonBanner(title: "New Friend Caught!", style: .accent)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.goldLight.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.goldMid.opacity(0.3), lineWidth: 1)
                        )

                    Image(def.stageImageNames.first ?? "pet_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(24)
                }
                .frame(height: 160)

                Text(def.name)
                    .font(AppTypography.petName)
                    .foregroundColor(AppColors.textPrimary)

                Text(def.description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .italic()
            }
        }
    }

    // MARK: - Helpers

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
