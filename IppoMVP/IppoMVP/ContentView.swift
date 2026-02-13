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
            
            RanksView()
                .tabItem {
                    Label("Ranks", systemImage: "shield.fill")
                }
                .tag(1)
            
            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(2)
        }
        .tint(AppColors.brandPrimary)
        .onAppear {
            // Check for RP decay and weekly reset on app launch
            userData.applyRPDecayIfNeeded()
            userData.checkWeeklyReset()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserData.shared)
        .environmentObject(WatchConnectivityService.shared)
}
