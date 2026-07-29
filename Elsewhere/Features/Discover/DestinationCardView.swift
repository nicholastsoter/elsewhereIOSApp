import SwiftUI

struct DestinationCardView: View {
    @EnvironmentObject private var appState: AppState
    let destination: Destination

    var body: some View {
        ElsewhereTheme.Color.dune
            .frame(height: 480)
            .overlay {
                AsyncImage(url: destination.heroImage?.url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure:            ElsewhereTheme.Color.dune
                    default:                  SkeletonView(cornerRadius: 0)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, ElsewhereTheme.Color.ink.opacity(0.85)],
                        startPoint: .center, endPoint: .bottom
                    )
                    cardContent
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.card))
            .overlay(alignment: .top) {
                if let score = destination.matchScore {
                    MatchBadge(percent: score)
                        .padding(ElsewhereTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name.uppercased())
                    .font(ElsewhereTheme.Font.title(26))
                Text(destination.country)
                    .font(ElsewhereTheme.Font.body(15))
                    .opacity(0.85)
            }

            if let explanation = destination.personalizedExplanation {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                Text(explanation)
                    .font(ElsewhereTheme.Font.display(16))
                    .lineLimit(4)
                    .opacity(0.95)
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
            }

            HStack {
                Label(costRangeText, systemImage: "dollarsign.circle")
                Spacer()
                Label(tripLengthText, systemImage: "calendar")
            }
            .font(ElsewhereTheme.Font.caption(12))
            .opacity(0.85)

            HStack(spacing: ElsewhereTheme.Spacing.xs) {
                ForEach(destination.categories.prefix(3)) { category in
                    Text(category.label)
                        .font(ElsewhereTheme.Font.caption(11))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Button {
                appState.setStatus(.someday, for: destination.id)
            } label: {
                Text(destination.saveStatus == nil ? "Save to Bucket List" : "Saved · \(destination.saveStatus!.label)")
                    .font(ElsewhereTheme.Font.title(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ElsewhereTheme.Color.sand)
                    .foregroundStyle(ElsewhereTheme.Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
            }
            .padding(.top, ElsewhereTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .padding(ElsewhereTheme.Spacing.md)
    }

    private var costRangeText: String {
        "$\(Int(destination.costEstimate.totalLow))–$\(Int(destination.costEstimate.totalHigh))"
    }
    private var tripLengthText: String {
        "\(destination.recommendedTripLengthDays.lowerBound)–\(destination.recommendedTripLengthDays.upperBound) days"
    }
}

#Preview {
    DestinationCardView(destination: MockData.destinations[0])
        .environmentObject(AppState())
        .padding()
}
