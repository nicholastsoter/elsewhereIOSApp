import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ForYouView()
            }
            .tabItem { Label("For You", systemImage: "sparkles") }

            NavigationStack {
                DiscoverView()
            }
            .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            NavigationStack {
                SavedView()
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }
        }
        .tint(ElsewhereTheme.Color.ink)
    }
}
