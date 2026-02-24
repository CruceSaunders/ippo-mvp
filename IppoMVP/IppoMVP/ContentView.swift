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
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(2)
        }
        .tint(AppColors.accent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.tabBar)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            userData.inventory.cleanExpiredBoosts()
            userData.checkRunaway()
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
