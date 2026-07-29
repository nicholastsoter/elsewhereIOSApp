import SwiftUI

// MARK: - Root container

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showingLeadIn: Bool

    @State private var step = 0

    // Step 1 — Interests (cards)
    @State private var selectedCategories: Set<TravelCategory> = []

    // Step 2 — Trait sliders (pre-populated from step 1 card selections)
    @State private var sliderAdventure:  Double = 0.5
    @State private var sliderNature:     Double = 0.5
    @State private var sliderBeaches:    Double = 0.5
    @State private var sliderCulture:    Double = 0.5
    @State private var sliderFood:       Double = 0.5
    @State private var sliderRoadTrips:  Double = 0.5
    @State private var crowdTolerance:   Double = 0.4
    @State private var physicalDifficulty: Double = 0.5
    @State private var budgetLevel:      BudgetLevel = .moderate
    @State private var tripLengthDays:   Double = 7

    // Step 3 — Companions
    @State private var selectedCompanions: Set<String> = []

    // Step 4 — Home region
    @State private var homeRegion: HomeRegion? = nil

    private static let contentStepCount = 4

    init(showingLeadIn: Binding<Bool> = .constant(false)) {
        _showingLeadIn = showingLeadIn
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if step > 0 {
                    progressBar
                        .padding(.top, ElsewhereTheme.Spacing.sm)
                        .padding(.bottom, ElsewhereTheme.Spacing.xs)
                        .transition(.opacity)
                }

                currentStepView
                    .id(step)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if step > 0 {
                    navBar
                        .padding(.horizontal, ElsewhereTheme.Spacing.md)
                        .padding(.bottom, ElsewhereTheme.Spacing.lg)
                        .padding(.top, ElsewhereTheme.Spacing.xs)
                        .transition(.opacity)
                }
            }
            .background(ElsewhereTheme.Color.sand.ignoresSafeArea())

            if showingLeadIn {
                SplashView(onDismiss: {
                    withAnimation(.easeOut(duration: 0.3)) { showingLeadIn = false }
                }, delay: 0.4)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    // MARK: Step routing

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 0: welcomeStep
        case 1: interestsStep
        case 2: travelStyleStep
        case 3: companionsStep
        default: homeRegionStep
        }
    }

    // MARK: Progress bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...Self.contentStepCount, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.dune)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, ElsewhereTheme.Spacing.md)
    }

    // MARK: Bottom nav

    private var canAdvance: Bool {
        switch step {
        case 1: return !selectedCategories.isEmpty
        case 4: return homeRegion != nil
        default: return true
        }
    }

    private var navBar: some View {
        HStack {
            if step > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { step -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Back")
                    }
                    .font(ElsewhereTheme.Font.body(15))
                    .foregroundStyle(ElsewhereTheme.Color.subtleText)
                }
            }

            Spacer()

            Button {
                if step == Self.contentStepCount {
                    finishOnboarding()
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) { step += 1 }
                }
            } label: {
                Text(step == Self.contentStepCount ? "Build My Profile" : "Next")
                    .font(ElsewhereTheme.Font.title(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, ElsewhereTheme.Spacing.lg)
                    .padding(.vertical, 13)
                    .background(canAdvance ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.dune)
                    .clipShape(Capsule())
            }
            .disabled(!canAdvance)
        }
    }

    // MARK: Build + save profile

    private func finishOnboarding() {
        // Traits without dedicated sliders use the binary card selection
        func cardScore(_ cat: TravelCategory) -> Double {
            selectedCategories.contains(cat) ? 0.85 : 0.2
        }

        let profile = TravelProfile(
            userID:               UUID(),
            adventure:            sliderAdventure,
            nature:               sliderNature,
            beaches:              sliderBeaches,
            luxury:               cardScore(.luxury),
            culture:              sliderCulture,
            history:              cardScore(.history),
            food:                 sliderFood,
            roadTrips:            sliderRoadTrips,
            remoteDestinations:   cardScore(.remote),
            cities:               cardScore(.cities),
            crowdTolerance:       crowdTolerance,
            physicalDifficulty:   physicalDifficulty,
            budgetLevel:          budgetLevel,
            typicalTripLengthDays: Int(tripLengthDays.rounded()),
            preferredCompanions:  Array(selectedCompanions),
            homeRegion:           homeRegion
        )

        appState.completeOnboarding(with: profile)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: ElsewhereTheme.Spacing.lg) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(ElsewhereTheme.Color.ink)

                VStack(spacing: ElsewhereTheme.Spacing.sm) {
                    Text("Where will you\ngo next?")
                        .font(ElsewhereTheme.Font.display(36))
                        .foregroundStyle(ElsewhereTheme.Color.ink)
                        .multilineTextAlignment(.center)

                    Text("Answer a few questions and we'll build a travel profile that matches you to real destinations — not generic top-10 lists.")
                        .font(ElsewhereTheme.Font.body(15))
                        .foregroundStyle(ElsewhereTheme.Color.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ElsewhereTheme.Spacing.xl)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.22)) { step = 1 }
            } label: {
                Text("Get Started")
                    .font(ElsewhereTheme.Font.title(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(ElsewhereTheme.Color.ink)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.lg)
            .padding(.bottom, ElsewhereTheme.Spacing.xl)
        }
    }

    // MARK: - Step 1: Interests

    private static let primaryCategories: [TravelCategory] = [
        .adventure, .nature, .beaches, .luxury,
        .culture, .history, .food, .roadTrips,
        .remote, .cities,
    ]

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.md) {
            stepHeader(
                title: "What moves you?",
                subtitle: "Select everything that excites you — even a little."
            )

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: ElsewhereTheme.Spacing.sm
                ) {
                    ForEach(Self.primaryCategories) { cat in
                        InterestCard(
                            category: cat,
                            isSelected: selectedCategories.contains(cat)
                        ) {
                            if selectedCategories.contains(cat) {
                                selectedCategories.remove(cat)
                            } else {
                                selectedCategories.insert(cat)
                            }
                        }
                    }
                }
                .padding(.horizontal, ElsewhereTheme.Spacing.md)
                .padding(.bottom, ElsewhereTheme.Spacing.sm)
            }
        }
        .padding(.top, ElsewhereTheme.Spacing.sm)
    }

    // MARK: - Step 2: Travel style (uses shared TraitSlidersView)

    private var travelStyleStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xl) {
                TraitSlidersView(
                    adventure:          $sliderAdventure,
                    nature:             $sliderNature,
                    beaches:            $sliderBeaches,
                    culture:            $sliderCulture,
                    food:               $sliderFood,
                    roadTrips:          $sliderRoadTrips,
                    crowdTolerance:     $crowdTolerance,
                    physicalDifficulty: $physicalDifficulty
                )

                VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.sm) {
                    Text("Budget").font(ElsewhereTheme.Font.title(15))
                    Picker("Budget", selection: $budgetLevel) {
                        ForEach(BudgetLevel.allCases, id: \.self) { b in
                            Text(b.rawValue.capitalized).tag(b)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
                    HStack {
                        Text("Typical trip length").font(ElsewhereTheme.Font.title(15))
                        Spacer()
                        Text("\(Int(tripLengthDays.rounded())) days")
                            .font(ElsewhereTheme.Font.body(15))
                            .foregroundStyle(ElsewhereTheme.Color.subtleText)
                    }
                    Slider(value: $tripLengthDays, in: 3...21, step: 1)
                        .tint(ElsewhereTheme.Color.ink)
                    HStack {
                        Text("3 days").font(ElsewhereTheme.Font.caption(11)).foregroundStyle(ElsewhereTheme.Color.subtleText)
                        Spacer()
                        Text("3 weeks").font(ElsewhereTheme.Font.caption(11)).foregroundStyle(ElsewhereTheme.Color.subtleText)
                    }
                }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.top, ElsewhereTheme.Spacing.md)
            .padding(.bottom, ElsewhereTheme.Spacing.xl)
        }
        .onAppear {
            let sel = selectedCategories
            func s(_ cat: TravelCategory) -> Double { sel.contains(cat) ? 0.85 : 0.2 }
            sliderAdventure = s(.adventure)
            sliderNature    = s(.nature)
            sliderBeaches   = s(.beaches)
            sliderCulture   = s(.culture)
            sliderFood      = s(.food)
            sliderRoadTrips = s(.roadTrips)
        }
    }

    // MARK: - Step 3: Companions

    private static let companions     = ["Solo", "Partner", "Friends", "Family", "Kids", "Groups"]
    private static let companionIcons = ["person.fill", "heart.fill", "person.2.fill",
                                         "house.fill", "figure.and.child.holdinghands", "person.3.fill"]

    private var companionsStep: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.lg) {
            stepHeader(title: "Who do you explore with?", subtitle: "Select all that apply.")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: ElsewhereTheme.Spacing.sm
            ) {
                ForEach(Array(Self.companions.enumerated()), id: \.offset) { i, label in
                    CompanionCard(
                        label: label,
                        icon: Self.companionIcons[i],
                        isSelected: selectedCompanions.contains(label)
                    ) {
                        if selectedCompanions.contains(label) {
                            selectedCompanions.remove(label)
                        } else {
                            selectedCompanions.insert(label)
                        }
                    }
                }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)

            Spacer()
        }
        .padding(.top, ElsewhereTheme.Spacing.sm)
    }

    // MARK: - Step 4: Home region

    private var homeRegionStep: some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.md) {
            stepHeader(
                title: "Where are you based?",
                subtitle: "Used to estimate flight costs. We don't track your location."
            )

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: ElsewhereTheme.Spacing.sm
                ) {
                    ForEach(HomeRegion.allCases, id: \.self) { region in
                        RegionCard(
                            region: region,
                            isSelected: homeRegion == region
                        ) {
                            homeRegion = region
                        }
                    }
                }
                .padding(.horizontal, ElsewhereTheme.Spacing.md)
                .padding(.bottom, ElsewhereTheme.Spacing.xl)
            }
        }
        .padding(.top, ElsewhereTheme.Spacing.sm)
    }

    // MARK: - Shared helpers

    private func stepHeader(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
            Text(title)
                .font(ElsewhereTheme.Font.display(26))
                .foregroundStyle(ElsewhereTheme.Color.ink)
            if let subtitle {
                Text(subtitle)
                    .font(ElsewhereTheme.Font.body(14))
                    .foregroundStyle(ElsewhereTheme.Color.subtleText)
            }
        }
        .padding(.horizontal, ElsewhereTheme.Spacing.md)
    }
}

// MARK: - Interest card (step 1)

private struct InterestCard: View {
    let category: TravelCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ElsewhereTheme.Spacing.sm) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 26))
                Text(category.label)
                    .font(ElsewhereTheme.Font.caption(13))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(isSelected ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.cardBackground)
            .foregroundStyle(isSelected ? .white : ElsewhereTheme.Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small)
                    .strokeBorder(isSelected ? Color.clear : ElsewhereTheme.Color.dune, lineWidth: 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.04), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Companion card (step 3)

private struct CompanionCard: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ElsewhereTheme.Spacing.xs) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(ElsewhereTheme.Font.caption(12))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.cardBackground)
            .foregroundStyle(isSelected ? .white : ElsewhereTheme.Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small)
                    .strokeBorder(isSelected ? Color.clear : ElsewhereTheme.Color.dune, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Region card (step 4)

private struct RegionCard: View {
    let region: HomeRegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ElsewhereTheme.Spacing.xs) {
                Text(region.rawValue)
                    .font(ElsewhereTheme.Font.caption(13))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, ElsewhereTheme.Spacing.sm)
            .padding(.vertical, ElsewhereTheme.Spacing.sm)
            .background(isSelected ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.cardBackground)
            .foregroundStyle(isSelected ? .white : ElsewhereTheme.Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small)
                    .strokeBorder(isSelected ? Color.clear : ElsewhereTheme.Color.dune, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
