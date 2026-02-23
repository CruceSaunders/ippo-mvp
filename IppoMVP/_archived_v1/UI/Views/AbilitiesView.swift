import SwiftUI

// MARK: - Starfield Background
struct StarfieldView: View {
    @State private var stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, speed: Double)] = []
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep space gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#05050A"),
                        Color(hex: "#0A0A18"),
                        Color(hex: "#080814")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Stars
                ForEach(0..<stars.count, id: \.self) { i in
                    let star = stars[i]
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity * (0.5 + 0.5 * sin(animationPhase * star.speed)))
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
                
                // Subtle nebula glow
                RadialGradient(
                    colors: [
                        AppColors.brandPrimary.opacity(0.03),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
            }
            .onAppear {
                generateStars()
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars() {
        stars = (0..<60).map { _ in
            (
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 0.5...2.5),
                opacity: Double.random(in: 0.2...0.8),
                speed: Double.random(in: 0.3...1.5)
            )
        }
    }
}

// MARK: - Main Abilities View
struct AbilitiesView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTab = 0
    @State private var selectedNode: AbilityNode?
    @State private var selectedPetForTree: OwnedPet?
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldView()
                
                VStack(spacing: 0) {
                    // Points Display
                    pointsDisplay
                    
                    // Tab Selector
                    Picker("", selection: $selectedTab) {
                        Text("Player").tag(0)
                        Text("Pets").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.vertical, AppSpacing.sm)
                    
                    // Content
                    if selectedTab == 0 {
                        playerAbilityTree
                    } else {
                        petAbilitiesView
                    }
                }
            }
            .navigationTitle("Abilities")
            .sheet(item: $selectedNode) { node in
                AbilityNodeSheet(node: node)
            }
            .sheet(item: $selectedPetForTree) { pet in
                PetAbilityTreeSheet(pet: pet)
            }
        }
    }
    
    // MARK: - Points Display
    private var pointsDisplay: some View {
        HStack(spacing: AppSpacing.xl) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(AppColors.brandPrimary)
                Text("AP: \(userData.abilities.abilityPoints)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "pawprint.circle.fill")
                    .foregroundColor(AppColors.gems)
                Text("PP: \(userData.abilities.petPoints)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface.opacity(0.85))
    }
    
    // MARK: - Player Ability Tree
    private var playerAbilityTree: some View {
        GeometryReader { geo in
            let treeWidth = max(geo.size.width * 1.3, 500)
            let treeHeight = max(geo.size.height * 1.4, 800)
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Draw edges with bezier curves
                    ForEach(AbilityTreeData.edges, id: \.from) { edge in
                        if let fromNode = AbilityTreeData.node(byId: edge.from),
                           let toNode = AbilityTreeData.node(byId: edge.to) {
                            bezierEdge(from: fromNode, to: toNode, treeSize: CGSize(width: treeWidth, height: treeHeight))
                        }
                    }
                    
                    // Draw nodes
                    ForEach(AbilityTreeData.playerNodes) { node in
                        playerNodeView(node, treeSize: CGSize(width: treeWidth, height: treeHeight))
                    }
                }
                .frame(width: treeWidth, height: treeHeight)
            }
        }
    }
    
    private func bezierEdge(from: AbilityNode, to: AbilityNode, treeSize: CGSize) -> some View {
        let fromPoint = CGPoint(x: from.treeX * treeSize.width, y: from.treeY * treeSize.height)
        let toPoint = CGPoint(x: to.treeX * treeSize.width, y: to.treeY * treeSize.height)
        let isUnlocked = userData.abilities.unlockedPlayerAbilities.contains(from.id) &&
                          userData.abilities.unlockedPlayerAbilities.contains(to.id)
        let isAvailable = userData.abilities.unlockedPlayerAbilities.contains(from.id)
        
        let midY = (fromPoint.y + toPoint.y) / 2
        
        return Path { path in
            path.move(to: fromPoint)
            path.addCurve(
                to: toPoint,
                control1: CGPoint(x: fromPoint.x, y: midY),
                control2: CGPoint(x: toPoint.x, y: midY)
            )
        }
        .stroke(
            isUnlocked ? AppColors.brandPrimary :
            isAvailable ? AppColors.brandPrimary.opacity(0.35) :
            AppColors.textTertiary.opacity(0.15),
            style: StrokeStyle(lineWidth: isUnlocked ? 3 : 2, lineCap: .round)
        )
    }
    
    private func playerNodeView(_ node: AbilityNode, treeSize: CGSize) -> some View {
        let isUnlocked = userData.abilities.unlockedPlayerAbilities.contains(node.id)
        let canUnlock = AbilityTreeSystem.shared.canUnlockAbility(node.id).canUnlock
        let nodeSize: CGFloat = node.tier == 0 ? 60 : 50
        
        return Button {
            selectedNode = node
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                ZStack {
                    // Glow effect for unlocked nodes
                    if isUnlocked {
                        Circle()
                            .fill(AppColors.brandPrimary.opacity(0.2))
                            .frame(width: nodeSize + 16, height: nodeSize + 16)
                            .blur(radius: 6)
                    }
                    
                    Circle()
                        .fill(
                            isUnlocked ? AppColors.brandPrimary :
                            canUnlock ? AppColors.surface :
                            AppColors.surfaceElevated
                        )
                        .frame(width: nodeSize, height: nodeSize)
                    
                    if isUnlocked || canUnlock {
                        Circle()
                            .stroke(
                                isUnlocked ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.5),
                                lineWidth: isUnlocked ? 3 : 2
                            )
                            .frame(width: nodeSize + 4, height: nodeSize + 4)
                    }
                    
                    Image(systemName: node.iconName)
                        .font(node.tier == 0 ? .title2 : .title3)
                        .foregroundColor(
                            isUnlocked ? AppColors.background :
                            canUnlock ? AppColors.brandPrimary :
                            AppColors.textTertiary
                        )
                }
                
                Text(node.name)
                    .font(AppTypography.caption2)
                    .foregroundColor(isUnlocked ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 80)
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.success)
                }
            }
        }
        .position(
            x: node.treeX * treeSize.width,
            y: node.treeY * treeSize.height
        )
    }
    
    // MARK: - Pet Abilities View
    private var petAbilitiesView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                if userData.ownedPets.isEmpty {
                    emptyPetsState
                } else {
                    ForEach(userData.ownedPets) { pet in
                        petAbilityCard(pet)
                    }
                }
            }
            .padding(AppSpacing.screenPadding)
        }
    }
    
    private var emptyPetsState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "pawprint")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No pets yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Catch pets during runs to unlock their ability trees")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
    }
    
    private func petAbilityCard(_ pet: OwnedPet) -> some View {
        let treeNodes = PetAbilityTreeData.treeForPet(pet.petDefinitionId)
        let unlockedCount = userData.abilities.petAbilityCount(for: pet.id)
        let totalCount = treeNodes.count
        
        return Button {
            selectedPetForTree = pet
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                        .frame(width: 50, height: 50)
                    Text(pet.definition?.emoji ?? "🐾")
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(pet.definition?.abilityName ?? "")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.brandPrimary)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Text("\(unlockedCount)/\(totalCount) abilities")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        
                        ProgressView(value: totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0)
                            .tint(AppColors.forPet(pet.petDefinitionId))
                            .frame(width: 60)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textTertiary)
                    .font(.caption)
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
        }
    }
}

// MARK: - Ability Node Sheet (Player)
struct AbilityNodeSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    let node: AbilityNode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                // Icon
                ZStack {
                    if isUnlocked {
                        Circle()
                            .fill(AppColors.brandPrimary.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .blur(radius: 8)
                    }
                    Circle()
                        .fill(isUnlocked ? AppColors.brandPrimary : AppColors.surface)
                        .frame(width: 80, height: 80)
                    Image(systemName: node.iconName)
                        .font(.largeTitle)
                        .foregroundColor(isUnlocked ? AppColors.background : AppColors.brandPrimary)
                }
                
                // Info
                VStack(spacing: AppSpacing.sm) {
                    Text(node.name)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(node.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tier \(node.tier) \u{2022} Cost: \(node.cost) AP")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // Prerequisites
                if !node.prerequisites.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Requires:")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textTertiary)
                        
                        ForEach(node.prerequisites, id: \.self) { prereqId in
                            if let prereq = AbilityTreeData.node(byId: prereqId) {
                                HStack {
                                    Image(systemName: userData.abilities.unlockedPlayerAbilities.contains(prereqId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(userData.abilities.unlockedPlayerAbilities.contains(prereqId) ? AppColors.success : AppColors.textTertiary)
                                    Text(prereq.name)
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                
                Spacer()
                
                // Action Button
                if isUnlocked {
                    Label("Unlocked", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.success)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(AppSpacing.radiusMd)
                } else {
                    let status = AbilityTreeSystem.shared.canUnlockAbility(node.id)
                    
                    Button {
                        if AbilityTreeSystem.shared.unlockAbility(node.id) {
                            HapticsManager.shared.playAbilityUnlock()
                            dismiss()
                        }
                    } label: {
                        Text(status.canUnlock ? "Unlock (\(node.cost) AP)" : (status.reason ?? "Cannot unlock"))
                            .font(AppTypography.headline)
                            .foregroundColor(status.canUnlock ? AppColors.textPrimary : AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(status.canUnlock ? AppColors.brandPrimary : AppColors.surfaceElevated)
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .disabled(!status.canUnlock)
                }
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.background)
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var isUnlocked: Bool {
        userData.abilities.unlockedPlayerAbilities.contains(node.id)
    }
}

// MARK: - Pet Ability Tree Sheet
struct PetAbilityTreeSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    let pet: OwnedPet
    @State private var selectedPetNode: PetAbilityNode?
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldView()
                
                VStack(spacing: 0) {
                    // Pet info header
                    petHeader
                    
                    // Tree
                    petTreeView
                }
            }
            .navigationTitle("\(pet.definition?.name ?? "Pet") Abilities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(item: $selectedPetNode) { node in
                let isUnlocked = userData.abilities.isPetNodeUnlocked(petId: pet.id, nodeId: node.id)
                let canUnlock = userData.abilities.canUnlockPetNode(petId: pet.id, node: node)
                
                return Alert(
                    title: Text(node.name),
                    message: Text("\(node.description)\n\nCost: \(node.cost) PP\n\(node.effect.description)"),
                    primaryButton: isUnlocked ? .default(Text("Unlocked")) {
                    } : canUnlock ? .default(Text("Unlock (\(node.cost) PP)")) {
                        if userData.unlockPetAbilityNode(pet.id, nodeId: node.id) {
                            HapticsManager.shared.playAbilityUnlock()
                        }
                    } : .default(Text("Not Available")) {},
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var petHeader: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(pet.definition?.emoji ?? "🐾")
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(pet.definition?.name ?? "Unknown")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("PP: \(userData.abilities.petPoints)")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.gems)
            }
            
            Spacer()
            
            let nodes = PetAbilityTreeData.treeForPet(pet.petDefinitionId)
            let unlocked = userData.abilities.petAbilityCount(for: pet.id)
            Text("\(unlocked)/\(nodes.count)")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface.opacity(0.85))
    }
    
    private var petTreeView: some View {
        GeometryReader { geo in
            let treeWidth = max(geo.size.width * 1.2, 380)
            let treeHeight = max(geo.size.height * 1.2, 600)
            let nodes = PetAbilityTreeData.treeForPet(pet.petDefinitionId)
            let edges = PetAbilityTreeData.edgesForPet(pet.petDefinitionId)
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Edges
                    ForEach(edges, id: \.from) { edge in
                        if let fromNode = PetAbilityTreeData.node(forPet: pet.petDefinitionId, nodeId: edge.from),
                           let toNode = PetAbilityTreeData.node(forPet: pet.petDefinitionId, nodeId: edge.to) {
                            petBezierEdge(from: fromNode, to: toNode, treeSize: CGSize(width: treeWidth, height: treeHeight))
                        }
                    }
                    
                    // Nodes
                    ForEach(nodes, id: \.id) { node in
                        petNodeView(node, treeSize: CGSize(width: treeWidth, height: treeHeight))
                    }
                }
                .frame(width: treeWidth, height: treeHeight)
            }
        }
    }
    
    private func petBezierEdge(from: PetAbilityNode, to: PetAbilityNode, treeSize: CGSize) -> some View {
        let fromPoint = CGPoint(x: from.treeX * treeSize.width, y: from.treeY * treeSize.height)
        let toPoint = CGPoint(x: to.treeX * treeSize.width, y: to.treeY * treeSize.height)
        let bothUnlocked = userData.abilities.isPetNodeUnlocked(petId: pet.id, nodeId: from.id) &&
                           userData.abilities.isPetNodeUnlocked(petId: pet.id, nodeId: to.id)
        let fromUnlocked = userData.abilities.isPetNodeUnlocked(petId: pet.id, nodeId: from.id)
        let midY = (fromPoint.y + toPoint.y) / 2
        let petColor = AppColors.forPet(pet.petDefinitionId)
        
        return Path { path in
            path.move(to: fromPoint)
            path.addCurve(to: toPoint, control1: CGPoint(x: fromPoint.x, y: midY), control2: CGPoint(x: toPoint.x, y: midY))
        }
        .stroke(
            bothUnlocked ? petColor : fromUnlocked ? petColor.opacity(0.35) : AppColors.textTertiary.opacity(0.15),
            style: StrokeStyle(lineWidth: bothUnlocked ? 3 : 2, lineCap: .round)
        )
    }
    
    private func petNodeView(_ node: PetAbilityNode, treeSize: CGSize) -> some View {
        let isUnlocked = userData.abilities.isPetNodeUnlocked(petId: pet.id, nodeId: node.id)
        let canUnlock = userData.abilities.canUnlockPetNode(petId: pet.id, node: node)
        let petColor = AppColors.forPet(pet.petDefinitionId)
        let nodeSize: CGFloat = node.tier == 0 ? 56 : (node.tier == 4 ? 56 : 46)
        
        return Button {
            selectedPetNode = node
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                ZStack {
                    if isUnlocked {
                        Circle()
                            .fill(petColor.opacity(0.25))
                            .frame(width: nodeSize + 14, height: nodeSize + 14)
                            .blur(radius: 5)
                    }
                    
                    Circle()
                        .fill(isUnlocked ? petColor : canUnlock ? AppColors.surface : AppColors.surfaceElevated)
                        .frame(width: nodeSize, height: nodeSize)
                    
                    if isUnlocked || canUnlock {
                        Circle()
                            .stroke(isUnlocked ? petColor : petColor.opacity(0.5), lineWidth: isUnlocked ? 3 : 2)
                            .frame(width: nodeSize + 4, height: nodeSize + 4)
                    }
                    
                    Image(systemName: node.iconName)
                        .font(node.tier == 0 || node.tier == 4 ? .title3 : .body)
                        .foregroundColor(isUnlocked ? AppColors.background : canUnlock ? petColor : AppColors.textTertiary)
                }
                
                Text(node.name)
                    .font(AppTypography.caption2)
                    .foregroundColor(isUnlocked ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 75)
            }
        }
        .position(x: node.treeX * treeSize.width, y: node.treeY * treeSize.height)
    }
}

#Preview {
    AbilitiesView()
        .environmentObject(UserData.shared)
}
