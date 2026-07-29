import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("Travel Personality") {
                Text(appState.profile.summary ?? "Complete onboarding to generate your travel personality.")
                    .font(ElsewhereTheme.Font.body(14))
            }
            Section("Preferences") {
                preferenceRow("Adventure", appState.profile.adventure)
                preferenceRow("Nature", appState.profile.nature)
                preferenceRow("Beaches", appState.profile.beaches)
                preferenceRow("Culture", appState.profile.culture)
                preferenceRow("Road Trips", appState.profile.roadTrips)
                preferenceRow("Remote Destinations", appState.profile.remoteDestinations)
            }
            Section("Trip Style") {
                LabeledContent("Budget", value: appState.profile.budgetLevel.rawValue.capitalized)
                LabeledContent("Typical trip length", value: "\(appState.profile.typicalTripLengthDays) days")
                LabeledContent("Crowd tolerance", value: "\(Int(appState.profile.crowdTolerance * 100))%")
                LabeledContent("Physical difficulty", value: "\(Int(appState.profile.physicalDifficulty * 100))%")
            }
        }
        .navigationTitle("Profile")
    }

    private func preferenceRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).font(ElsewhereTheme.Font.body(14))
            Spacer()
            ProgressView(value: value)
                .frame(width: 100)
                .tint(ElsewhereTheme.Color.sunset)
        }
    }
}

#Preview {
    NavigationStack { ProfileView().environmentObject(AppState()) }
}
