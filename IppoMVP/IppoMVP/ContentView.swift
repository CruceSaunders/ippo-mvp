import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            PetsView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint.fill")
                }
                .tag(1)
            
            AbilitiesView()
                .tabItem {
                    Label("Abilities", systemImage: "bolt.fill")
                }
                .tag(2)
            
            RanksView()
                .tabItem {
                    Label("Ranks", systemImage: "shield.fill")
                }
                .tag(3)
            
            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
                .tag(4)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(5)
        }
        .tint(AppColors.brandPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserData.shared)
        .environmentObject(WatchConnectivityService.shared)
}
