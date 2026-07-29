import Foundation

enum CostTier: String, Codable, CaseIterable {
    case budget, moderate, premium, luxury
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case easy, moderate, challenging, strenuous
}

enum CrowdLevel: String, Codable, CaseIterable {
    case low, moderate, high
}

enum TravelCategory: String, Codable, CaseIterable, Identifiable {
    case adventure, nature, beaches, luxury, culture, history, food, roadTrips, remote, cities
    case mountains, unique, wellness
    var id: String { rawValue }

    var label: String {
        switch self {
        case .roadTrips:  return "Road Trips"
        case .remote:     return "Remote"
        case .mountains:  return "Mountains"
        case .unique:     return "Unique"
        case .wellness:   return "Wellness"
        default:          return rawValue.capitalized
        }
    }

    var systemImage: String {
        switch self {
        case .adventure:  return "figure.hiking"
        case .nature:     return "leaf.fill"
        case .beaches:    return "sun.horizon.fill"
        case .luxury:     return "star.fill"
        case .culture:    return "building.columns.fill"
        case .history:    return "scroll.fill"
        case .food:       return "fork.knife"
        case .roadTrips:  return "car.fill"
        case .remote:     return "map.fill"
        case .cities:     return "building.2.fill"
        case .mountains:  return "mountain.2.fill"
        case .unique:     return "sparkles"
        case .wellness:   return "heart.fill"
        }
    }
}

struct CostEstimate: Codable, Equatable {
    var flightsLow: Double
    var flightsHigh: Double
    var lodgingLow: Double
    var lodgingHigh: Double
    var foodLow: Double
    var foodHigh: Double
    var transportationLow: Double
    var transportationHigh: Double
    var activitiesLow: Double
    var activitiesHigh: Double
    var isLive: Bool = false          // false unless backed by a real pricing API
    var lastUpdated: Date = Date()

    var totalLow: Double {
        flightsLow + lodgingLow + foodLow + transportationLow + activitiesLow
    }
    var totalHigh: Double {
        flightsHigh + lodgingHigh + foodHigh + transportationHigh + activitiesHigh
    }
}

struct DestinationImage: Codable, Identifiable, Equatable {
    let id: String
    let url: URL
    let thumbnailURL: URL?
    let width: Int
    let height: Int
    let photographer: String
    let provider: String              // e.g. "unsplash", "pexels", "mock"
    let attributionURL: URL?
    var licenseNote: String?
    var tags: [String] = []

    var isLandscape: Bool { width >= height }
}

struct ItineraryDay: Codable, Identifiable, Equatable {
    let id: UUID
    var dayNumber: Int
    var title: String
    var summary: String
}

struct Destination: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var country: String
    var region: String
    var latitude: Double
    var longitude: Double

    var summary: String
    var personalizedExplanation: String?     // AI-generated, filled per-user
    var explanationAnchors: [String] = []    // specific profile traits that ground the explanation
    var matchScore: Int?                      // 0-100, filled per-user

    var categories: [TravelCategory]
    var activities: [String]
    var bestMonths: [Int]                     // 1-12
    var recommendedTripLengthDays: ClosedRange<Int>

    var costEstimate: CostEstimate
    var costTier: CostTier
    var difficulty: DifficultyLevel
    var crowdLevel: CrowdLevel

    var heroImage: DestinationImage?
    var supportingImages: [DestinationImage]

    var similarDestinationIDs: [UUID]
    var popularAttractions: [String]
    var sampleItinerary: [ItineraryDay]

    var saveStatus: SavedStatus?
}

enum SavedStatus: String, Codable, CaseIterable, Identifiable {
    case someday, interested, planning, booked, completed
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}
