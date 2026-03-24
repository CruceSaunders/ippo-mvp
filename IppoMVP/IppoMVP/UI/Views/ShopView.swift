import SwiftUI

struct ShopView: View {
    @EnvironmentObject var userData: UserData
    @State private var purchaseMessage: String?
    @State private var showPurchaseMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                ParchmentBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        coinBalance

                        shopSection(title: "Essentials", items: [.food, .water, .foodPack, .waterPack])
                        shopSection(title: "Boosts", items: [.xpBoost, .encounterCharm, .coinBoost])
                        shopSection(title: "Protection", items: [.hibernation, .streakFreeze])
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Market")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .overlay {
                if showPurchaseMessage, let msg = purchaseMessage {
                    VStack {
                        Spacer()
                        StoryBookCard {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                                Text(msg)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: showPurchaseMessage)
                }
            }
        }
    }

    private var coinBalance: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.coins)
                Text("\(userData.profile.coins) coins")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusLg)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
            Spacer()
        }
        .padding(.top, 8)
    }

    private func shopSection(title: String, items: [ShopItemType]) -> some View {
        VStack(spacing: 12) {
            RibbonBanner(title: title)

            let essentialItems = items.filter { [.food, .water, .foodPack, .waterPack].contains($0) }
            let otherItems = items.filter { ![.food, .water, .foodPack, .waterPack].contains($0) }

            if essentialItems.count >= 2 {
                let rows = stride(from: 0, to: essentialItems.count, by: 2).map {
                    Array(essentialItems[$0..<min($0 + 2, essentialItems.count)])
                }
                ForEach(rows, id: \.first?.rawValue) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.rawValue) { itemType in
                            if let item = ShopItem.allItems.first(where: { $0.type == itemType }) {
                                shopItemCard(item: item)
                            }
                        }
                        if row.count == 1 {
                            Spacer().frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            ForEach(otherItems, id: \.rawValue) { itemType in
                if let item = ShopItem.allItems.first(where: { $0.type == itemType }) {
                    shopItemRow(item: item)
                }
            }
        }
    }

    private func shopItemCard(item: ShopItem) -> some View {
        StoryBookCard {
            VStack(spacing: 8) {
                Image(systemName: item.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.accent)
                    .frame(height: 36)

                Text(item.name)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text(item.description)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)

                GoldButton(
                    title: "",
                    coinAmount: item.cost,
                    isDisabled: userData.profile.coins < item.cost,
                    size: .compact
                ) {
                    buy(item)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func shopItemRow(item: ShopItem) -> some View {
        StoryBookCard {
            HStack(spacing: 12) {
                Image(systemName: item.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(AppTypography.cardTitle)
                        .foregroundColor(AppColors.textPrimary)
                    Text(item.description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                GoldButton(
                    title: "",
                    coinAmount: item.cost,
                    isDisabled: userData.profile.coins < item.cost,
                    size: .compact
                ) {
                    buy(item)
                }
            }
        }
    }

    private func buy(_ item: ShopItem) {
        if userData.buyItem(item.type) {
            SoundManager.shared.play(.shopPurchase)
            purchaseMessage = "Bought \(item.name)!"
            showPurchaseMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPurchaseMessage = false
            }
        }
    }
}
