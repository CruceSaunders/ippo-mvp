import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var userData: UserData
    @State private var showShop = false
    @State private var selectedPetId: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        ownedPetsSection
                        undiscoveredSection
                        lostPetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showShop) {
                ShopSheet()
                    .environmentObject(userData)
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Pets")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(userData.activePets.count)/\(GameData.petDefinitions.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Button {
                showShop = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bag.fill")
                    Text("Shop")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColors.accent)
                .cornerRadius(10)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Owned Pets
    @ViewBuilder
    private var ownedPetsSection: some View {
        if !userData.activePets.isEmpty {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(userData.activePets) { pet in
                    PetGridCell(pet: pet)
                        .onTapGesture {
                            selectedPetId = pet.id
                        }
                }
            }
        }
    }

    // MARK: - Undiscovered
    @ViewBuilder
    private var undiscoveredSection: some View {
        let undiscovered = GameData.petDefinitions.filter { def in
            !userData.ownedPetDefinitionIds.contains(def.id) && !def.isStarter
        }

        if !undiscovered.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Undiscovered")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                LazyVGrid(columns: columns, spacing: 12) {
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
            VStack(alignment: .leading, spacing: 10) {
                Text("Lost Pets")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.danger)

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
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surface)

                PetImageView(imageName: pet.currentImageName, size: 80)
                    .padding(12)
            }
            .frame(height: 100)
            .overlay(
                pet.isEquipped ?
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.accent, lineWidth: 2)
                    : nil
            )

            Text(pet.definition?.name ?? "???")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Text("Stg. \(pet.evolutionStage)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Undiscovered Cell
struct UndiscoveredCell: View {
    let definition: GamePetDefinition

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceElevated)

                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
            .frame(height: 100)

            Text("???")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textTertiary)

            Text(definition.hintText)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Lost Pet Row
struct LostPetRow: View {
    let pet: OwnedPet
    @EnvironmentObject var userData: UserData

    var body: some View {
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
            }

            Spacer()

            let cost = PetConfig.shared.rescueCost(forStage: pet.evolutionStage)
            Button {
                _ = userData.rescuePet(pet.id)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("\(cost)")
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(AppColors.coins)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.accent)
                .cornerRadius(8)
            }
            .disabled(userData.profile.coins < cost)
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}
