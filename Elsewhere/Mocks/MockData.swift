import Foundation

enum MockData {

    static func image(_ seed: String, w: Int = 1200, h: Int = 1600, tag: String) -> DestinationImage {
        DestinationImage(
            id: seed,
            url: URL(string: "https://picsum.photos/id/\(seed)/\(w)/\(h)")!,
            thumbnailURL: URL(string: "https://picsum.photos/id/\(seed)/300/400")!,
            width: w, height: h,
            photographer: "Mock Photographer",
            provider: "mock",
            attributionURL: URL(string: "https://picsum.photos"),
            tags: [tag]
        )
    }

    static let destinations: [Destination] = [
        Destination(
            id: UUID(),
            name: "Patagonia",
            country: "Chile & Argentina",
            region: "South America",
            latitude: -50.5, longitude: -73.0,
            summary: "Dramatic granite peaks, glaciers, and multi-day treks at the edge of the world.",
            personalizedExplanation: "You've said you prefer remote landscapes over crowds and lean toward strenuous, self-directed trips — Patagonia is as close to a perfect match as a destination gets.",
            explanationAnchors: ["Remote landscapes", "Low crowd tolerance", "Strenuous activity"],
            matchScore: 94,
            categories: [.adventure, .nature, .remote],
            activities: ["Trek Torres del Paine", "Glacier boat tour", "Wildlife spotting"],
            bestMonths: [11, 12, 1, 2, 3],
            recommendedTripLengthDays: 8...12,
            costEstimate: CostEstimate(
                flightsLow: 900, flightsHigh: 1400,
                lodgingLow: 700, lodgingHigh: 1200,
                foodLow: 300, foodHigh: 500,
                transportationLow: 300, transportationHigh: 600,
                activitiesLow: 200, activitiesHigh: 500
            ),
            costTier: .moderate,
            difficulty: .strenuous,
            crowdLevel: .low,
            heroImage: image("1015", tag: "patagonia"),
            supportingImages: [image("1018", tag: "patagonia"), image("1021", tag: "patagonia")],
            similarDestinationIDs: [],
            popularAttractions: ["Torres del Paine", "Perito Moreno Glacier", "Fitz Roy"],
            sampleItinerary: [
                ItineraryDay(id: UUID(), dayNumber: 1, title: "Arrival in Puerto Natales", summary: "Settle in, gear check, scenic dinner."),
                ItineraryDay(id: UUID(), dayNumber: 2, title: "Torres del Paine day hike", summary: "Full-day trek to the base of the towers.")
            ],
            saveStatus: nil
        ),
        Destination(
            id: UUID(),
            name: "South Island",
            country: "New Zealand",
            region: "Oceania",
            latitude: -43.5, longitude: 170.5,
            summary: "Fjords, alpine passes, and coastline made for a slow road trip.",
            personalizedExplanation: "Your profile scores road trips and remote destinations near the top — South Island is one of the world's great road trip routes through genuinely remote terrain.",
            explanationAnchors: ["Road trips: top preference", "Remote destinations", "Dramatic landscapes"],
            matchScore: 91,
            categories: [.roadTrips, .nature, .adventure],
            activities: ["Milford Sound cruise", "Queenstown hikes", "Stargazing at Lake Tekapo"],
            bestMonths: [12, 1, 2, 3],
            recommendedTripLengthDays: 10...14,
            costEstimate: CostEstimate(
                flightsLow: 1100, flightsHigh: 1700,
                lodgingLow: 900, lodgingHigh: 1600,
                foodLow: 400, foodHigh: 700,
                transportationLow: 400, transportationHigh: 800,
                activitiesLow: 300, activitiesHigh: 700
            ),
            costTier: .moderate,
            difficulty: .moderate,
            crowdLevel: .moderate,
            heroImage: image("1025", tag: "new-zealand"),
            supportingImages: [image("1035", tag: "new-zealand")],
            similarDestinationIDs: [],
            popularAttractions: ["Milford Sound", "Lake Tekapo", "Queenstown"],
            sampleItinerary: [],
            saveStatus: .interested
        ),
        Destination(
            id: UUID(),
            name: "Kyoto",
            country: "Japan",
            region: "Asia",
            latitude: 35.0, longitude: 135.8,
            summary: "Temples, seasonal gardens, and centuries of craft and cuisine.",
            personalizedExplanation: "You score high on culture and food and seem drawn to places with deep historical layers — Kyoto rewards exactly that kind of unhurried, exploratory attention.",
            explanationAnchors: ["Culture: high interest", "Food travel", "History"],
            matchScore: 82,
            categories: [.culture, .history, .food],
            activities: ["Fushimi Inari at sunrise", "Tea ceremony", "Arashiyama bamboo grove"],
            bestMonths: [3, 4, 10, 11],
            recommendedTripLengthDays: 5...8,
            costEstimate: CostEstimate(
                flightsLow: 800, flightsHigh: 1300,
                lodgingLow: 600, lodgingHigh: 1400,
                foodLow: 350, foodHigh: 600,
                transportationLow: 150, transportationHigh: 300,
                activitiesLow: 150, activitiesHigh: 400
            ),
            costTier: .moderate,
            difficulty: .easy,
            crowdLevel: .high,
            heroImage: image("1043", tag: "kyoto"),
            supportingImages: [image("1051", tag: "kyoto")],
            similarDestinationIDs: [],
            popularAttractions: ["Fushimi Inari", "Kinkaku-ji", "Arashiyama"],
            sampleItinerary: [],
            saveStatus: nil
        )
    ]

    static let profile = TravelProfile(
        userID: UUID(),
        summary: "You gravitate toward remote, dramatic landscapes and active, self-directed trips over resort-style relaxation.",
        adventure: 0.9, nature: 0.95, beaches: 0.35, luxury: 0.25,
        culture: 0.7, history: 0.55, food: 0.7, roadTrips: 0.85,
        remoteDestinations: 0.9, cities: 0.4,
        crowdTolerance: 0.2, physicalDifficulty: 0.75,
        budgetLevel: .moderate, typicalTripLengthDays: 8,
        preferredCompanions: ["spouse", "friends"]
    )
}
