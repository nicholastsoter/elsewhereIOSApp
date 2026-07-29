import SwiftUI

/// Shared profile-tuning sliders used in onboarding (step 2) and the For You refinement sheet.
/// Any change here is reflected in both places automatically.
struct TraitSlidersView: View {
    @Binding var adventure:          Double
    @Binding var nature:             Double
    @Binding var beaches:            Double
    @Binding var culture:            Double
    @Binding var food:               Double
    @Binding var roadTrips:          Double
    @Binding var crowdTolerance:     Double
    @Binding var physicalDifficulty: Double

    var body: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.lg) {
            Text("Search")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ElsewhereTheme.Color.subtleText)
                .kerning(1.5)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.lg) {
                traitRow("Adventure",  value: $adventure)
                traitRow("Nature",     value: $nature)
                traitRow("Beaches",    value: $beaches)
                traitRow("Culture",    value: $culture)
                traitRow("Food",       value: $food)
                traitRow("Road Trips", value: $roadTrips)
            }

            Divider()

            VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.lg) {
                labeledRow("Crowd preference",
                           left: "Hidden gems", right: "Buzzing spots",
                           value: $crowdTolerance)
                labeledRow("Physical level",
                           left: "Relaxed",     right: "Strenuous",
                           value: $physicalDifficulty)
            }
        }
    }

    private func traitRow(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
            Text(title).font(ElsewhereTheme.Font.title(15))
            Slider(value: value).tint(ElsewhereTheme.Color.ink)
        }
    }

    private func labeledRow(_ title: String, left: String, right: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
            Text(title).font(ElsewhereTheme.Font.title(15))
            Slider(value: value).tint(ElsewhereTheme.Color.ink)
            HStack {
                Text(left).font(ElsewhereTheme.Font.caption(11)).foregroundStyle(ElsewhereTheme.Color.subtleText)
                Spacer()
                Text(right).font(ElsewhereTheme.Font.caption(11)).foregroundStyle(ElsewhereTheme.Color.subtleText)
            }
        }
    }
}
