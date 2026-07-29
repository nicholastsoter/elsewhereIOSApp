import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab = SavedTab.saved

    enum SavedTab: String, CaseIterable {
        case saved = "Saved"
        case trips = "Trips"
        case profile = "Profile"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(SavedTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.vertical, ElsewhereTheme.Spacing.sm)
            .background(ElsewhereTheme.Color.sand)

            Group {
                switch tab {
                case .saved:   BucketListView()
                case .trips:   TripsView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
        .navigationDestination(for: UUID.self) { id in
            if let destination = appState.destinations.first(where: { $0.id == id }) {
                DestinationDetailView(destination: destination)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedView().environmentObject(AppState())
    }
}
