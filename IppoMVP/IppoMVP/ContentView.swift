import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "pawprint.fill")
                }
                .tag(0)

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            ShopView()
                .tabItem {
                    Label("Market", systemImage: "bag.fill")
                }
                .tag(2)
        }
        .tint(AppColors.tabActive)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.tabBar)

            let normalAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(AppColors.tabInactive)
            ]
            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(AppColors.tabActive)
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.tabInactive)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.tabActive)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            userData.inventory.cleanExpiredBoosts()
            if let idx = userData.ownedPets.firstIndex(where: { $0.isEquipped && !$0.isLost }) {
                userData.recalculateMood(at: idx)
            }
            userData.checkRunaway()
            userData.checkAndActivateCareNeed()
            NotificationSystem.shared.rescheduleNotifications()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserData.shared)
        .environmentObject(AuthService.shared)
        .environmentObject(WatchConnectivityService.shared)
}
