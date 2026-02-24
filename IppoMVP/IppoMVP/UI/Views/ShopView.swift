import SwiftUI

struct ShopView: View {
    @EnvironmentObject var userData: UserData
    @State private var purchaseMessage: String?
    @State private var showPurchaseMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        coinBalance
                        shopSection(title: "Essentials", items: [.food, .water, .foodPack, .waterPack])
                        shopSection(title: "Boosts", items: [.xpBoost, .encounterBoost])
                        shopSection(title: "Special", items: [.hibernation])
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if showPurchaseMessage, let msg = purchaseMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.success)
                            .cornerRadius(10)
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
            Image(systemName: "circle.fill")
                .font(.system(size: 12))
                .foregroundColor(AppColors.coins)
            Text("\(userData.profile.coins) coins")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }

    private func shopSection(title: String, items: [ShopItemType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            ForEach(items, id: \.rawValue) { itemType in
                if let item = ShopItem.allItems.first(where: { $0.type == itemType }) {
                    shopItemRow(item: item)
                }
            }
        }
    }

    private func shopItemRow(item: ShopItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 20))
                .foregroundColor(AppColors.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(item.description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button {
                buy(item)
            } label: {
                HStack(spacing: 4) {
                    Text("\(item.cost)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(AppColors.coins)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    userData.profile.coins >= item.cost
                        ? AppColors.accent
                        : AppColors.textTertiary
                )
                .cornerRadius(8)
            }
            .disabled(userData.profile.coins < item.cost)
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    private func buy(_ item: ShopItem) {
        if userData.buyItem(item.type) {
            purchaseMessage = "Bought \(item.name)!"
            showPurchaseMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPurchaseMessage = false
            }
        }
    }
}
