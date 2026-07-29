import SwiftUI

struct ForYouView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSearchSheet = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: ElsewhereTheme.Spacing.xl) {
                header
                ForEach(appState.destinations) { destination in
                    NavigationLink(value: destination.id) {
                        DestinationCardView(destination: destination)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.bottom, ElsewhereTheme.Spacing.xl)
        }
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSearchSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(ElsewhereTheme.Color.ink)
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let destination = appState.destinations.first(where: { $0.id == id }) {
                DestinationDetailView(destination: destination)
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheetView()
                .environmentObject(appState)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
            Text("For You")
                .font(ElsewhereTheme.Font.display(30))
                .foregroundStyle(ElsewhereTheme.Color.ink)
            if let summary = appState.profile.summary {
                Text(summary)
                    .font(ElsewhereTheme.Font.body(14))
                    .foregroundStyle(ElsewhereTheme.Color.subtleText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, ElsewhereTheme.Spacing.sm)
    }
}

// MARK: - Search sheet

private struct SearchSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var adventure:          Double = 0.5
    @State private var nature:             Double = 0.5
    @State private var beaches:            Double = 0.5
    @State private var culture:            Double = 0.5
    @State private var food:               Double = 0.5
    @State private var roadTrips:          Double = 0.5
    @State private var crowdTolerance:     Double = 0.5
    @State private var physicalDifficulty: Double = 0.5

    var body: some View {
        NavigationStack {
            ScrollView {
                TraitSlidersView(
                    adventure:          $adventure,
                    nature:             $nature,
                    beaches:            $beaches,
                    culture:            $culture,
                    food:               $food,
                    roadTrips:          $roadTrips,
                    crowdTolerance:     $crowdTolerance,
                    physicalDifficulty: $physicalDifficulty
                )
                .padding(.horizontal, ElsewhereTheme.Spacing.md)
                .padding(.top, ElsewhereTheme.Spacing.md)
                .padding(.bottom, ElsewhereTheme.Spacing.xl)
            }
            .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
            .navigationTitle("Refine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ElsewhereTheme.Color.subtleText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update my results") {
                        applyChanges()
                        dismiss()
                    }
                    .font(ElsewhereTheme.Font.title(15))
                    .foregroundStyle(ElsewhereTheme.Color.ink)
                }
            }
        }
        .onAppear { loadFromProfile() }
    }

    private func loadFromProfile() {
        let p = appState.profile
        adventure          = p.adventure
        nature             = p.nature
        beaches            = p.beaches
        culture            = p.culture
        food               = p.food
        roadTrips          = p.roadTrips
        crowdTolerance     = p.crowdTolerance
        physicalDifficulty = p.physicalDifficulty
    }

    private func applyChanges() {
        appState.profile.adventure          = adventure
        appState.profile.nature             = nature
        appState.profile.beaches            = beaches
        appState.profile.culture            = culture
        appState.profile.food               = food
        appState.profile.roadTrips          = roadTrips
        appState.profile.crowdTolerance     = crowdTolerance
        appState.profile.physicalDifficulty = physicalDifficulty
        ProfileStore.save(appState.profile)
        appState.recomputeMatches()
    }
}

#Preview {
    NavigationStack {
        ForYouView()
            .environmentObject(AppState())
    }
}
