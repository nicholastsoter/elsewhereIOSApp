import SwiftUI

/// Placeholder for Phase 6: trip planning + itinerary generation.
/// Populated once a destination moves to "Planning" status.
struct TripsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let planning = appState.destinations.filter { $0.saveStatus == .planning || $0.saveStatus == .booked }

        Group {
            if planning.isEmpty {
                VStack(spacing: ElsewhereTheme.Spacing.sm) {
                    Image(systemName: "airplane.departure").font(.system(size: 40)).foregroundStyle(ElsewhereTheme.Color.dune)
                    Text("No trips in progress").font(ElsewhereTheme.Font.title(18))
                    Text("Move a bucket list destination to Planning to start building a trip.")
                        .font(ElsewhereTheme.Font.body(14))
                        .foregroundStyle(ElsewhereTheme.Color.subtleText)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(planning) { destination in
                    Text(destination.name)
                }
            }
        }
        .navigationTitle("Trips")
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { TripsView().environmentObject(AppState()) }
}
