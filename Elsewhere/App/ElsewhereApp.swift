import SwiftUI
import Combine

@main
struct ElsewhereApp: App {
    @StateObject private var appState    = AppState()
    @State private var showingSplash     = true
    @State private var showingOBLeadIn   = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if appState.hasCompletedOnboarding {
                        RootTabView()
                    } else {
                        OnboardingView(showingLeadIn: $showingOBLeadIn)
                    }
                }
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)

                if showingSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.3)) { showingSplash = false }
                        if !appState.hasCompletedOnboarding { showingOBLeadIn = true }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var profile: TravelProfile
    @Published var destinations: [Destination]
    @Published var hasCompletedOnboarding: Bool

    init() {
        let saved = ProfileStore.load()
        self.profile               = saved ?? TravelProfile(userID: UUID())
        self.hasCompletedOnboarding = ProfileStore.hasCompletedOnboarding
        if let saved {
            self.destinations = AppState.buildDestinations(for: saved)
        } else {
            self.destinations = DestinationLoader.loadAll()
        }
    }

    func completeOnboarding(with profile: TravelProfile) {
        self.profile = profile
        ProfileStore.save(profile)
        ProfileStore.hasCompletedOnboarding = true
        hasCompletedOnboarding = true
        recomputeMatches()
    }

    func recomputeMatches() {
        // Snapshot save statuses — the only user state stored inside destinations
        let statuses = Dictionary(
            uniqueKeysWithValues: destinations.compactMap { d in d.saveStatus.map { (d.id, $0) } }
        )
        var updated = AppState.buildDestinations(for: profile)
        if !statuses.isEmpty {
            updated = updated.map { d in
                var copy = d
                copy.saveStatus = statuses[d.id]
                return copy
            }
        }
        destinations = updated
    }

    func setStatus(_ status: SavedStatus?, for destinationID: UUID) {
        guard let idx = destinations.firstIndex(where: { $0.id == destinationID }) else { return }
        destinations[idx].saveStatus = status
    }

    var bucketList: [Destination] {
        destinations.filter { $0.saveStatus != nil }
    }

    // Always rebuilds from the raw bundle JSON so flight costs are never
    // double-adjusted when recomputeMatches() is called more than once.
    private static func buildDestinations(for profile: TravelProfile) -> [Destination] {
        let raw     = DestinationLoader.loadAll()
        var updated = MatchingEngine.apply(profile: profile, to: raw)
        if let homeRegion = profile.homeRegion {
            updated = CostEstimator.applyFlightCosts(homeRegion: homeRegion, to: updated)
        }
        return updated
    }
}
