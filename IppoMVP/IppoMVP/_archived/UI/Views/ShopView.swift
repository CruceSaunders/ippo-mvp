import SwiftUI

struct ShopView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var selectedLootBox: Rarity?
    @State private var isOpeningLootBox = false
    @State private var lootBoxContents: LootBoxContents?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Currency Bar
                    currencyBar
                    
                    // Loot Boxes Inventory
                    lootBoxInventory
                    
                    // Pet Care Section
                    petCareSection
                    
                    // Boosts Section
                    boostsSection
                    
                    // Loot Box Purchase Section
                    lootBoxPurchaseSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Shop")
            .alert("Purchase", isPresented: $showingPurchaseAlert) {
                Button("OK") {}
            } message: {
                Text(purchaseMessage)
            }
            .sheet(item: $selectedLootBox) { rarity in
                LootBoxOpeningSheet(rarity: rarity, contents: $lootBoxContents)
            }
        }
    }
    
    // MARK: - Currency Bar
    private var currencyBar: some View {
        HStack(spacing: AppSpacing.xl) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.gold)
                    .font(.title2)
                Text("\(userData.coins)")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(AppColors.gems)
                    .font(.title2)
                Text("\(userData.gems)")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - Loot Box Inventory
    private var lootBoxInventory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Your Loot Boxes")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(userData.inventory.totalLootBoxes) total")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if userData.inventory.totalLootBoxes == 0 {
                Text("No loot boxes. Earn them by completing sprints!")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(Rarity.allCases, id: \.self) { rarity in
                            let count = userData.inventory.lootBoxes[rarity, default: 0]
                            if count > 0 {
                                lootBoxCard(rarity: rarity, count: count)
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private func lootBoxCard(rarity: Rarity, count: Int) -> some View {
        Button {
            selectedLootBox = rarity
        } label: {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                        .fill(AppColors.forRarity(rarity).opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "gift.fill")
                        .font(.title)
                        .foregroundColor(AppColors.forRarity(rarity))
                    
                    // Count badge
                    Text("\(count)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.xs)
                        .background(AppColors.background)
                        .cornerRadius(AppSpacing.radiusSm)
                        .offset(x: 25, y: -25)
                }
                
                Text(rarity.displayName)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.forRarity(rarity))
                
                Text("Tap to open")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
    
    // MARK: - Pet Care Section
    private var petCareSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Pet Care")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            shopItemRow(
                icon: "leaf.fill",
                iconColor: AppColors.success,
                name: "Pet Food",
                description: "Extra feeding for any pet",
                price: 100,
                currency: .coins
            ) {
                if userData.spendCoins(100) {
                    userData.inventory.petFood += 1
                    purchaseMessage = "Purchased Pet Food!"
                    showingPurchaseAlert = true
                    HapticsManager.shared.playSuccess()
                } else {
                    purchaseMessage = "Not enough coins!"
                    showingPurchaseAlert = true
                    HapticsManager.shared.playError()
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Boosts Section
    private var boostsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Boosts")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            shopItemRow(
                icon: "bolt.fill",
                iconColor: AppColors.warning,
                name: "XP Boost (1 hour)",
                description: "+50% XP from all sources",
                price: 500,
                currency: .coins
            ) {
                if userData.spendCoins(500) {
                    userData.inventory.xpBoosts += 1
                    purchaseMessage = "Purchased XP Boost!"
                    showingPurchaseAlert = true
                    HapticsManager.shared.playSuccess()
                } else {
                    purchaseMessage = "Not enough coins!"
                    showingPurchaseAlert = true
                    HapticsManager.shared.playError()
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Loot Box Purchase Section
    private var lootBoxPurchaseSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Buy Loot Boxes")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.md) {
                lootBoxPurchaseCard(rarity: .uncommon, price: 50)
                lootBoxPurchaseCard(rarity: .rare, price: 200)
                lootBoxPurchaseCard(rarity: .epic, price: 500)
            }
        }
        .cardStyle()
    }
    
    private func lootBoxPurchaseCard(rarity: Rarity, price: Int) -> some View {
        Button {
            if userData.spendGems(price) {
                userData.addLootBox(rarity)
                purchaseMessage = "Purchased \(rarity.displayName) Loot Box!"
                showingPurchaseAlert = true
                HapticsManager.shared.playSuccess()
            } else {
                purchaseMessage = "Not enough gems!"
                showingPurchaseAlert = true
                HapticsManager.shared.playError()
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                        .fill(AppColors.forRarity(rarity).opacity(0.2))
                        .frame(height: 60)
                    
                    Image(systemName: "gift.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.forRarity(rarity))
                }
                
                Text(rarity.displayName)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xxxs) {
                    Image(systemName: "diamond.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.gems)
                    Text("\(price)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.gems)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
        }
    }
    
    // MARK: - Shop Item Row
    private func shopItemRow(
        icon: String,
        iconColor: Color,
        name: String,
        description: String,
        price: Int,
        currency: Currency,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(name)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text(description)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: currency == .coins ? "dollarsign.circle.fill" : "diamond.fill")
                        .foregroundColor(currency == .coins ? AppColors.gold : AppColors.gems)
                    Text("\(price)")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.surfaceElevated)
                .cornerRadius(AppSpacing.radiusSm)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Loot Box Opening Sheet (CS:GO Style)
struct LootBoxOpeningSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    let rarity: Rarity
    @Binding var contents: LootBoxContents?
    
    enum OpeningPhase {
        case ready
        case spinning
        case slowing
        case revealed
    }
    
    @State private var phase: OpeningPhase = .ready
    @State private var spinItems: [SpinItem] = []
    @State private var winningIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var finalContents: LootBoxContents?
    
    // Spin configuration
    private let itemWidth: CGFloat = 100
    private let itemSpacing: CGFloat = 8
    private let totalItems = 50 // Items in the spin strip
    private let visibleItems = 5 // Items visible at once
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            switch phase {
            case .ready:
                readyView
            case .spinning, .slowing:
                spinningView
            case .revealed:
                revealedView
            }
            
            Spacer()
            
            // Button
            bottomButton
        }
        .padding(AppSpacing.screenPadding)
        .background(AppColors.background)
        .onAppear {
            generateSpinItems()
        }
    }
    
    // MARK: - Ready View
    private var readyView: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                    .fill(AppColors.forRarity(rarity).opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.forRarity(rarity))
            }
            
            Text("\(rarity.displayName) Loot Box")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.forRarity(rarity))
            
            Text("Tap to spin!")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Spinning View (CS:GO Style Carousel)
    private var spinningView: some View {
        VStack(spacing: AppSpacing.xl) {
            // Title
            Text(phase == .slowing ? "Slowing down..." : "Spinning...")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
            
            // Spin carousel
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(AppColors.surface)
                    .frame(height: 140)
                
                // Items carousel
                GeometryReader { geometry in
                    let centerX = geometry.size.width / 2
                    
                    HStack(spacing: itemSpacing) {
                        ForEach(Array(spinItems.enumerated()), id: \.offset) { index, item in
                            SpinItemView(
                                item: item,
                                isHighlighted: isItemHighlighted(index: index, centerX: centerX),
                                highlightProgress: highlightProgress(index: index, centerX: centerX)
                            )
                            .frame(width: itemWidth)
                        }
                    }
                    .offset(x: -scrollOffset + centerX - itemWidth / 2)
                }
                .frame(height: 120)
                .clipped()
                
                // Selection indicator (pointer)
                VStack(spacing: 0) {
                    // Top arrow
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.brandPrimary)
                    
                    Spacer()
                    
                    // Bottom arrow
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.brandPrimary)
                }
                .frame(height: 150)
                
                // Glow lines on sides
                HStack {
                    LinearGradient(
                        colors: [AppColors.background, AppColors.background.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 40)
                    
                    Spacer()
                    
                    LinearGradient(
                        colors: [AppColors.background.opacity(0), AppColors.background],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 40)
                }
                .frame(height: 140)
            }
            .frame(height: 150)
            
            // Rarity indicator
            Text("Opening \(rarity.displayName) Loot Box")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.forRarity(rarity))
        }
    }
    
    // MARK: - Revealed View
    private var revealedView: some View {
        VStack(spacing: AppSpacing.lg) {
            // Celebration emoji
            Text("🎉")
                .font(.system(size: 60))
            
            if let item = spinItems[safe: winningIndex] {
                // Show the winning item prominently
                VStack(spacing: AppSpacing.md) {
                    // Tier badge
                    Text(item.tier.displayName)
                        .font(AppTypography.caption1)
                        .foregroundColor(item.tier.color)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(item.tier.color.opacity(0.2))
                        .cornerRadius(AppSpacing.radiusSm)
                    
                    // Rewards
                    VStack(spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(AppColors.gold)
                                .font(.title)
                            Text("+\(item.coins)")
                                .font(AppTypography.largeTitle)
                                .foregroundColor(AppColors.gold)
                        }
                        
                        if item.gems > 0 {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "diamond.fill")
                                    .foregroundColor(AppColors.gems)
                                    .font(.title)
                                Text("+\(item.gems)")
                                    .font(AppTypography.largeTitle)
                                    .foregroundColor(AppColors.gems)
                            }
                        }
                    }
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Bottom Button
    private var bottomButton: some View {
        Group {
            switch phase {
            case .ready:
                Button {
                    startSpin()
                } label: {
                    Text("Spin!")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.forRarity(rarity))
                        .cornerRadius(AppSpacing.radiusMd)
                }
            case .spinning, .slowing:
                Text("Good luck!")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.surfaceElevated)
                    .cornerRadius(AppSpacing.radiusMd)
            case .revealed:
                Button {
                    dismiss()
                } label: {
                    Text("Collect")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.brandPrimary)
                        .cornerRadius(AppSpacing.radiusMd)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func isItemHighlighted(index: Int, centerX: CGFloat) -> Bool {
        let itemCenterX = CGFloat(index) * (itemWidth + itemSpacing) + itemWidth / 2 - scrollOffset + centerX - itemWidth / 2
        let distance = abs(itemCenterX - centerX)
        return distance < itemWidth / 2
    }
    
    private func highlightProgress(index: Int, centerX: CGFloat) -> CGFloat {
        let itemCenterX = CGFloat(index) * (itemWidth + itemSpacing) + itemWidth / 2 - scrollOffset + centerX - itemWidth / 2
        let distance = abs(itemCenterX - centerX)
        let maxDistance = itemWidth
        return max(0, 1 - distance / maxDistance)
    }
    
    // MARK: - Generate Spin Items
    private func generateSpinItems() {
        // First, determine the actual winning contents
        finalContents = LootBoxContents.generate(for: rarity)
        
        // Generate items with proper distribution based on loot box rarity
        var items: [SpinItem] = []
        
        for i in 0..<totalItems {
            let item = generateRandomSpinItem(for: rarity)
            items.append(item)
        }
        
        // Place the winning item near the end (where the spin will land)
        // This creates the classic CS:GO effect where you "almost" get better items
        winningIndex = totalItems - 8 + Int.random(in: 0...3)
        
        // Create the winning item from our actual contents
        if let contents = finalContents {
            let winningItem = SpinItem(
                coins: contents.coins,
                gems: contents.gems,
                tier: SpinItem.determineTier(coins: contents.coins, gems: contents.gems, forRarity: rarity)
            )
            items[winningIndex] = winningItem
        }
        
        spinItems = items
    }
    
    private func generateRandomSpinItem(for rarity: Rarity) -> SpinItem {
        // Generate random rewards within the loot box rarity's range
        // with weighted distribution (more common = more frequent)
        let tierRoll = Double.random(in: 0...1)
        let tier: SpinItemTier
        
        // Weighted distribution: Common items appear more frequently
        if tierRoll < 0.50 {
            tier = .common
        } else if tierRoll < 0.80 {
            tier = .uncommon
        } else if tierRoll < 0.95 {
            tier = .rare
        } else {
            tier = .jackpot
        }
        
        return SpinItem.generate(for: rarity, tier: tier)
    }
    
    // MARK: - Start Spin Animation
    private func startSpin() {
        phase = .spinning
        HapticsManager.shared.playLootBoxOpen()
        
        // Calculate final scroll position to land on winning item
        let targetOffset = CGFloat(winningIndex) * (itemWidth + itemSpacing)
        
        // Add some extra spin (full rotations through the strip)
        let extraSpins = CGFloat(totalItems) * (itemWidth + itemSpacing) * 2
        let totalDistance = extraSpins + targetOffset
        
        // Animate the spin with easing
        withAnimation(.easeIn(duration: 0.5)) {
            scrollOffset = itemWidth * 3 // Quick start
        }
        
        // Fast spin phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 2.0)) {
                scrollOffset = totalDistance * 0.7
            }
            
            // Play tick sounds during fast spin
            startTickSounds(duration: 2.0, interval: 0.08)
        }
        
        // Slowing down phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = .slowing
            
            withAnimation(.easeOut(duration: 2.5)) {
                scrollOffset = targetOffset
            }
            
            // Slower ticks as it slows
            startTickSounds(duration: 2.5, interval: 0.15)
        }
        
        // Reveal phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Actually consume the loot box and add rewards
            if let contents = finalContents {
                _ = userData.openLootBox(rarity)
                self.contents = contents
            }
            
            HapticsManager.shared.playSuccess()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .revealed
            }
        }
    }
    
    private func startTickSounds(duration: Double, interval: Double) {
        let ticks = Int(duration / interval)
        for i in 0..<ticks {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                if phase == .spinning || phase == .slowing {
                    HapticsManager.shared.playTick()
                }
            }
        }
    }
}

// MARK: - Spin Item Model
struct SpinItem: Identifiable {
    let id = UUID()
    let coins: Int
    let gems: Int
    let tier: SpinItemTier
    
    static func generate(for rarity: Rarity, tier: SpinItemTier) -> SpinItem {
        let (coinRange, gemRange) = tier.ranges(for: rarity)
        let coins = Int.random(in: coinRange)
        let gems = gemRange.isEmpty ? 0 : Int.random(in: gemRange)
        return SpinItem(coins: coins, gems: gems, tier: tier)
    }
    
    static func determineTier(coins: Int, gems: Int, forRarity rarity: Rarity) -> SpinItemTier {
        // Determine tier based on how good the rewards are relative to the rarity
        let (_, _, maxCoins, maxGems) = rarity.rewardRanges
        let coinPercent = Double(coins) / Double(maxCoins)
        let gemPercent = maxGems > 0 ? Double(gems) / Double(maxGems) : 0
        let avgPercent = (coinPercent + gemPercent) / (maxGems > 0 ? 2 : 1)
        
        if avgPercent > 0.85 { return .jackpot }
        if avgPercent > 0.65 { return .rare }
        if avgPercent > 0.35 { return .uncommon }
        return .common
    }
}

// MARK: - Spin Item Tier (for color coding)
enum SpinItemTier: CaseIterable {
    case common      // Gray - low end of range
    case uncommon    // Green - mid-low
    case rare        // Blue - mid-high
    case jackpot     // Gold/Orange - high end (best possible)
    
    var displayName: String {
        switch self {
        case .common: return "Standard"
        case .uncommon: return "Good"
        case .rare: return "Great"
        case .jackpot: return "Jackpot!"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return AppColors.rarityCommon
        case .uncommon: return AppColors.rarityUncommon
        case .rare: return AppColors.rarityRare
        case .jackpot: return AppColors.rarityLegendary
        }
    }
    
    func ranges(for rarity: Rarity) -> (ClosedRange<Int>, ClosedRange<Int>) {
        let (minCoins, minGems, maxCoins, maxGems) = rarity.rewardRanges
        let coinSpread = maxCoins - minCoins
        let gemSpread = maxGems - minGems
        
        switch self {
        case .common:
            let coinLow = minCoins
            let coinHigh = minCoins + coinSpread / 4
            let gemLow = minGems
            let gemHigh = minGems + gemSpread / 4
            return (coinLow...max(coinLow, coinHigh), gemHigh > 0 ? gemLow...max(gemLow, gemHigh) : 0...0)
            
        case .uncommon:
            let coinLow = minCoins + coinSpread / 4
            let coinHigh = minCoins + coinSpread / 2
            let gemLow = minGems + gemSpread / 4
            let gemHigh = minGems + gemSpread / 2
            return (coinLow...coinHigh, gemHigh > 0 ? gemLow...gemHigh : 0...0)
            
        case .rare:
            let coinLow = minCoins + coinSpread / 2
            let coinHigh = minCoins + (3 * coinSpread) / 4
            let gemLow = minGems + gemSpread / 2
            let gemHigh = minGems + (3 * gemSpread) / 4
            return (coinLow...coinHigh, gemHigh > 0 ? gemLow...gemHigh : 0...0)
            
        case .jackpot:
            let coinLow = minCoins + (3 * coinSpread) / 4
            let coinHigh = maxCoins
            let gemLow = minGems + (3 * gemSpread) / 4
            let gemHigh = maxGems
            return (coinLow...coinHigh, gemHigh > 0 ? gemLow...gemHigh : 0...0)
        }
    }
}

// MARK: - Spin Item View
struct SpinItemView: View {
    let item: SpinItem
    let isHighlighted: Bool
    let highlightProgress: CGFloat
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            // Coins
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.gold)
                    .font(.caption)
                Text("\(item.coins)")
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Gems (if any)
            if item.gems > 0 {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(AppColors.gems)
                        .font(.caption2)
                    Text("\(item.gems)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.gems)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                .fill(item.tier.color.opacity(0.15 + highlightProgress * 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                .stroke(item.tier.color.opacity(0.5 + highlightProgress * 0.5), lineWidth: isHighlighted ? 3 : 2)
        )
        .scaleEffect(1.0 + highlightProgress * 0.15)
        .shadow(color: isHighlighted ? item.tier.color.opacity(0.5) : .clear, radius: 8)
        .animation(.easeOut(duration: 0.1), value: isHighlighted)
    }
}

// MARK: - Rarity Extension for Reward Ranges
extension Rarity {
    var rewardRanges: (minCoins: Int, minGems: Int, maxCoins: Int, maxGems: Int) {
        switch self {
        case .common:
            return (50, 0, 100, 0)
        case .uncommon:
            return (100, 5, 200, 10)
        case .rare:
            return (200, 10, 400, 25)
        case .epic:
            return (400, 25, 800, 50)
        case .legendary:
            return (800, 50, 1500, 100)
        }
    }
}

// Make Rarity Identifiable for sheet
extension Rarity: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ShopView()
        .environmentObject(UserData.shared)
}
