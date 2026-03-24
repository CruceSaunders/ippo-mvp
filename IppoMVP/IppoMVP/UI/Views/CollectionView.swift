import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedPetId: String?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ParchmentBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        ownedPetsSection
                        undiscoveredSection
                        lostPetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Collection")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .sheet(item: selectedPetBinding) { pet in
                PetDetailView(pet: pet)
                    .environmentObject(userData)
            }
        }
    }

    private var selectedPetBinding: Binding<OwnedPet?> {
        Binding(
            get: {
                guard let id = selectedPetId else { return nil }
                return userData.ownedPets.first { $0.id == id }
            },
            set: { selectedPetId = $0?.id }
        )
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(userData.ownedPetDefinitionIds.count) of \(GameData.petDefinitions.count) Discovered")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            collectionProgressBar
        }
        .padding(.top, 8)
    }

    private var collectionProgressBar: some View {
        let total = GameData.petDefinitions.count
        let owned = userData.ownedPetDefinitionIds.count
        let progress = total > 0 ? CGFloat(owned) / CGFloat(total) : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.surfaceDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.goldMid],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * progress - 2), height: 10)
                    .padding(.leading, 2)
                    .shadow(color: AppColors.goldMid.opacity(0.4), radius: 2, y: 0)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 14)
    }

    // MARK: - Owned Pets
    @ViewBuilder
    private var ownedPetsSection: some View {
        if !userData.activePets.isEmpty {
            VStack(spacing: 12) {
                RibbonBanner(title: "My Pets")

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(userData.activePets) { pet in
                        PetGridCell(pet: pet)
                            .onTapGesture {
                                selectedPetId = pet.id
                            }
                    }
                }
            }
        }
    }

    // MARK: - Undiscovered
    @ViewBuilder
    private var undiscoveredSection: some View {
        let undiscovered = GameData.petDefinitions.filter { def in
            !userData.ownedPetDefinitionIds.contains(def.id)
        }

        if !undiscovered.isEmpty {
            VStack(spacing: 12) {
                RibbonBanner(title: "Undiscovered", style: .small)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(undiscovered) { def in
                        UndiscoveredCell(definition: def)
                    }
                }
            }
        }
    }

    // MARK: - Lost Pets
    @ViewBuilder
    private var lostPetsSection: some View {
        if !userData.lostPets.isEmpty {
            VStack(spacing: 12) {
                RibbonBanner(title: "Lost Pets", style: .small)

                ForEach(userData.lostPets) { pet in
                    LostPetRow(pet: pet)
                }
            }
        }
    }
}

// MARK: - Pet Grid Cell
struct PetGridCell: View {
    let pet: OwnedPet

    var body: some View {
        StoryBookCard(isHighlighted: pet.isEquipped) {
            VStack(spacing: 8) {
                PetImageView(imageName: pet.currentImageName, size: 80)
                    .frame(height: 90)

                Text(pet.definition?.name ?? "???")
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.forMood(pet.mood))
                        Text(moodLabel(pet.mood))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.forMood(pet.mood))
                    }

                    Spacer()

                    Text("Lv. \(pet.level)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private func moodLabel(_ mood: Int) -> String {
        switch mood {
        case 3: return "Happy"
        case 2: return "Content"
        default: return "Sad"
        }
    }
}

// MARK: - Undiscovered Cell
struct UndiscoveredCell: View {
    let definition: GamePetDefinition

    var body: some View {
        StoryBookCard {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.surfaceDark.opacity(0.5))
                        .frame(height: 90)

                    Image(definition.stageImageNames.first ?? "pet_placeholder")
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .colorMultiply(.black)
                        .opacity(0.12)

                    Text("?")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(AppColors.borderBrown.opacity(0.4))
                }

                Text("???")
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textTertiary)

                Text(definition.hintText)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Lost Pet Row
struct LostPetRow: View {
    let pet: OwnedPet
    @EnvironmentObject var userData: UserData

    var body: some View {
        StoryBookCard {
            HStack(spacing: 12) {
                PetImageView(imageName: pet.currentImageName, size: 50)
                    .frame(width: 50, height: 50)
                    .saturation(0)
                    .opacity(0.6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Ran away...")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.danger)
                        .italic()
                }

                Spacer()

                let cost = PetConfig.shared.rescueCost(forStage: pet.evolutionStage)
                GoldButton(
                    title: "Rescue",
                    icon: "arrow.uturn.backward.circle.fill",
                    coinAmount: cost,
                    isDisabled: userData.profile.coins < cost,
                    size: .compact
                ) {
                    _ = userData.rescuePet(pet.id)
                }
            }
        }
    }
}
