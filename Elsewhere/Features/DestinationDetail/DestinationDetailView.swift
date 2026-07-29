import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var appState: AppState
    let destination: Destination

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.lg) {
                hero
                whyYouMightLoveIt
                tripOverview
                costBreakdown
                if !destination.popularAttractions.isEmpty { thingsToDo }
                if !destination.sampleItinerary.isEmpty { sampleItinerary }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.bottom, ElsewhereTheme.Spacing.xl)
        }
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ElsewhereTheme.Color.dune
            .frame(height: 420)
            .overlay {
                if let url = destination.heroImage?.url {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            SkeletonView(cornerRadius: 0)
                        }
                    }
                }
            }
            .overlay {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.clear, ElsewhereTheme.Color.ink.opacity(0.8)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        if let score = destination.matchScore { MatchBadge(percent: score) }
                        Text(destination.name)
                            .font(ElsewhereTheme.Font.display(30))
                            .foregroundStyle(.white)
                        Text(destination.country)
                            .font(ElsewhereTheme.Font.body(15))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ElsewhereTheme.Spacing.md)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.card))
    }

    private var whyYouMightLoveIt: some View {
        WhyLoveItSection(
            explanation: destination.personalizedExplanation ?? destination.summary,
            anchors: destination.explanationAnchors
        )
    }

    private var tripOverview: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
            Text("Trip Overview").font(ElsewhereTheme.Font.title())
            HStack(spacing: ElsewhereTheme.Spacing.lg) {
                overviewStat("Length", "\(destination.recommendedTripLengthDays.lowerBound)–\(destination.recommendedTripLengthDays.upperBound)d")
                overviewStat("Difficulty", destination.difficulty.rawValue.capitalized)
                overviewStat("Crowds", destination.crowdLevel.rawValue.capitalized)
            }
        }
    }

    private func overviewStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(ElsewhereTheme.Font.title(16))
            Text(label).font(ElsewhereTheme.Font.caption()).foregroundStyle(ElsewhereTheme.Color.subtleText)
        }
    }

    private var costBreakdown: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
            HStack {
                Text("Estimated Cost").font(ElsewhereTheme.Font.title())
                Spacer()
                Text(destination.costEstimate.isLive ? "LIVE PRICE" : "ESTIMATED")
                    .font(ElsewhereTheme.Font.caption(10))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(destination.costEstimate.isLive ? ElsewhereTheme.Color.palm : ElsewhereTheme.Color.dune)
                    .foregroundStyle(destination.costEstimate.isLive ? .white : ElsewhereTheme.Color.ink)
                    .clipShape(Capsule())
            }
            costRow("Flights", destination.costEstimate.flightsLow, destination.costEstimate.flightsHigh)
            costRow("Hotels", destination.costEstimate.lodgingLow, destination.costEstimate.lodgingHigh)
            costRow("Food", destination.costEstimate.foodLow, destination.costEstimate.foodHigh)
            costRow("Transportation", destination.costEstimate.transportationLow, destination.costEstimate.transportationHigh)
            costRow("Activities", destination.costEstimate.activitiesLow, destination.costEstimate.activitiesHigh)
            Divider()
            HStack {
                Text("Estimated total").font(ElsewhereTheme.Font.title(16))
                Spacer()
                Text("$\(Int(destination.costEstimate.totalLow))–$\(Int(destination.costEstimate.totalHigh))")
                    .font(ElsewhereTheme.Font.title(16))
            }
        }
        .padding(ElsewhereTheme.Spacing.md)
        .background(ElsewhereTheme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
    }

    private func costRow(_ label: String, _ low: Double, _ high: Double) -> some View {
        HStack {
            Text(label).font(ElsewhereTheme.Font.body(14)).foregroundStyle(ElsewhereTheme.Color.subtleText)
            Spacer()
            Text("$\(Int(low))–$\(Int(high))").font(ElsewhereTheme.Font.body(14))
        }
    }

    private var thingsToDo: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
            Text("Things To Do").font(ElsewhereTheme.Font.title())
            ForEach(destination.popularAttractions, id: \.self) { item in
                Text("• \(item)").font(ElsewhereTheme.Font.body(14))
            }
        }
    }

    private var sampleItinerary: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
            Text("Sample Itinerary").font(ElsewhereTheme.Font.title())
            ForEach(destination.sampleItinerary) { day in
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAY \(day.dayNumber)").font(ElsewhereTheme.Font.caption())
                    Text(day.title).font(ElsewhereTheme.Font.body(15))
                    Text(day.summary).font(ElsewhereTheme.Font.body(13)).foregroundStyle(ElsewhereTheme.Color.subtleText)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct WhyLoveItSection: View {
    let explanation: String
    let anchors: [String]
    @State private var visible = false

    var body: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.md) {
            Text("Why You Might Love It")
                .font(ElsewhereTheme.Font.title())

            Text(explanation)
                .font(ElsewhereTheme.Font.display(20))
                .foregroundStyle(ElsewhereTheme.Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 10)

            if !anchors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ElsewhereTheme.Spacing.xs) {
                        ForEach(anchors, id: \.self) { anchor in
                            Text(anchor)
                                .font(ElsewhereTheme.Font.caption(12))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(ElsewhereTheme.Color.sunset.opacity(0.18))
                                .foregroundStyle(ElsewhereTheme.Color.ink)
                                .clipShape(Capsule())
                        }
                    }
                }
                .opacity(visible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.25)) {
                visible = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        DestinationDetailView(destination: MockData.destinations[0])
            .environmentObject(AppState())
    }
}
