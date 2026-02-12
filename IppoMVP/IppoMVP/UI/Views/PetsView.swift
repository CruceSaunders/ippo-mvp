import SwiftUI

struct PetsView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedPet: OwnedPet?
    @State private var showingFeedResult: FeedResult?
    @State private var showingEvolution = false
    @State private var evolutionPet: OwnedPet?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Equipped Pet Detail
                    if let pet = userData.equippedPet {
                        equippedPetCard(pet)
                    }
                    
                    // Collection
                    collectionSection
                    
                    // Undiscovered
                    undiscoveredSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("My Pets")
            .sheet(item: $selectedPet) { pet in
                PetDetailSheet(pet: pet)
            }
            .alert("Fed!", isPresented: .constant(showingFeedResult != nil)) {
                Button("OK") { showingFeedResult = nil }
            } message: {
                if let result = showingFeedResult {
                    Text(result.didEvolve ? "🎉 \(result.message) Stage \(result.newStage ?? 0)!" : result.message)
                }
            }
        }
    }
    
    // MARK: - Equipped Pet Card
    private func equippedPetCard(_ pet: OwnedPet) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Equipped")
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textTertiary)
            
            HStack(spacing: AppSpacing.md) {
                // Pet Image
                ZStack {
                    Circle()
                        .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                        .frame(width: 80, height: 80)
                    Text(pet.definition?.emoji ?? "🐾")
                        .font(.system(size: 40))
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(pet.stageName) (Stage \(pet.evolutionStage))")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    // Ability
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppColors.brandPrimary)
                            .font(.caption)
                        Text(pet.definition?.abilityName ?? "")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    
                    // XP Progress
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        ProgressView(value: pet.xpProgress)
                            .tint(AppColors.forPet(pet.petDefinitionId))
                        Text("\(pet.experience) / \(pet.xpForNextStage) XP")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: AppSpacing.sm) {
                    Text(pet.moodEmoji)
                        .font(.largeTitle)
                    Text("Mood: \(pet.mood)/10")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Actions
            HStack(spacing: AppSpacing.sm) {
                Button {
                    let result = PetSystem.shared.feedPet(pet.id)
                    if result.success {
                        showingFeedResult = result
                        HapticsManager.shared.playSuccess()
                    } else {
                        HapticsManager.shared.playError()
                    }
                } label: {
                    HStack {
                        Image(systemName: "leaf.fill")
                        Text("Feed")
                        if pet.canBeFed {
                            Text("(\(PetConfig.shared.maxFeedingsPerDay - pet.feedingsToday) left)")
                                .font(AppTypography.caption2)
                        }
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(pet.canBeFed ? AppColors.textPrimary : AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(pet.canBeFed ? AppColors.success.opacity(0.2) : AppColors.surfaceElevated)
                    .cornerRadius(AppSpacing.radiusSm)
                }
                .disabled(!pet.canBeFed)
                
                Button {
                    selectedPet = pet
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.surfaceElevated)
                    .cornerRadius(AppSpacing.radiusSm)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Collection Section
    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Collection")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: AppSpacing.md) {
                ForEach(userData.ownedPets) { pet in
                    petCard(pet)
                }
            }
        }
    }
    
    private func petCard(_ pet: OwnedPet) -> some View {
        Button {
            selectedPet = pet
        } label: {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                        .frame(width: 60, height: 60)
                    Text(pet.definition?.emoji ?? "🐾")
                        .font(.title)
                    
                    if pet.isEquipped {
                        Circle()
                            .stroke(AppColors.brandPrimary, lineWidth: 2)
                            .frame(width: 64, height: 64)
                    }
                }
                
                Text(pet.definition?.name ?? "?")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Stage \(pet.evolutionStage)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                if pet.isEquipped {
                    Text("★ Equipped")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.brandPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
        }
    }
    
    // MARK: - Undiscovered Section
    private var undiscoveredSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Undiscovered (\(10 - userData.ownedPets.count))")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: AppSpacing.md) {
                ForEach(undiscoveredPets, id: \.id) { pet in
                    undiscoveredCard(pet)
                }
            }
        }
    }
    
    private var undiscoveredPets: [GamePetDefinition] {
        GameData.shared.allPets.filter { def in
            !userData.ownedPetIds.contains(def.id)
        }
    }
    
    private func undiscoveredCard(_ pet: GamePetDefinition) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(AppColors.surfaceElevated)
                .frame(width: 60, height: 60)
                .overlay(
                    Text("?")
                        .font(.title)
                        .foregroundColor(AppColors.textTertiary)
                )
            
            Text(pet.name)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textTertiary)
            
            Text("???")
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .background(AppColors.surface.opacity(0.5))
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Pet Detail Sheet
struct PetDetailSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    let pet: OwnedPet
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Pet Header
                    VStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.3))
                                .frame(width: 120, height: 120)
                            Text(pet.definition?.emoji ?? "🐾")
                                .font(.system(size: 60))
                        }
                        
                        Text(pet.definition?.name ?? "Unknown")
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(pet.stageName)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(pet.definition?.description ?? "")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Stats")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        statRow("Evolution Stage", "\(pet.evolutionStage)/10")
                        statRow("Experience", "\(pet.experience) XP")
                        statRow("Mood", "\(pet.mood)/10 \(pet.moodEmoji)")
                        statRow("Ability Level", "★\(pet.abilityLevel)/5")
                        statRow("Caught", pet.caughtDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .cardStyle()
                    
                    // Ability
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Ability")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppColors.brandPrimary)
                            Text(pet.definition?.abilityName ?? "")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.brandPrimary)
                        }
                        
                        Text(pet.definition?.abilityDescription ?? "")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Effectiveness: \(Int(pet.abilityEffectiveness * 100))%")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .cardStyle()
                    
                    // Actions
                    if !pet.isEquipped {
                        Button {
                            userData.equipPet(pet.id)
                            HapticsManager.shared.playSuccess()
                            dismiss()
                        } label: {
                            Text("Equip Pet")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.brandPrimary)
                                .cornerRadius(AppSpacing.radiusMd)
                        }
                    }
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(AppColors.background)
            .navigationTitle(pet.definition?.name ?? "Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    PetsView()
        .environmentObject(UserData.shared)
}
