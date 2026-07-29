import Foundation

enum BudgetLevel: String, Codable, CaseIterable {
    case shoestring, moderate, comfortable, luxury
}

/// Departure region for flight cost estimation. Each case maps to a representative
/// city lat/lon used only for distance bucketing — no actual geolocation is performed.
enum HomeRegion: String, Codable, CaseIterable {
    case usWest        = "US – West"
    case usMidwest     = "US – Midwest"
    case usSouth       = "US – South"
    case usNortheast   = "US – Northeast"
    case canada        = "Canada"
    case latinAmerica  = "Latin America"
    case westernEurope = "Western Europe"
    case easternEurope = "Eastern Europe"
    case middleEast    = "Middle East"
    case africa        = "Africa"
    case southAsia     = "South Asia"
    case eastAsia      = "East Asia"
    case southeastAsia = "Southeast Asia"
    case oceania       = "Oceania"

    var coordinate: (lat: Double, lon: Double) {
        switch self {
        case .usWest:        return (37.8,  -122.4)
        case .usMidwest:     return (41.9,   -87.6)
        case .usSouth:       return (29.7,   -95.4)
        case .usNortheast:   return (40.7,   -74.0)
        case .canada:        return (43.7,   -79.4)
        case .latinAmerica:  return (-23.5,  -46.6)
        case .westernEurope: return (48.9,     2.4)
        case .easternEurope: return (52.2,    21.0)
        case .middleEast:    return (25.2,    55.3)
        case .africa:        return (-26.2,   28.0)
        case .southAsia:     return (28.6,    77.2)
        case .eastAsia:      return (35.7,   139.7)
        case .southeastAsia: return (1.3,    103.8)
        case .oceania:       return (-33.9,  151.2)
        }
    }
}

/// A user's evolving travel personality. Scores are 0.0–1.0 and are nudged
/// over time by save/reject/complete behavior rather than only set at onboarding.
struct TravelProfile: Codable, Equatable {
    var userID: UUID
    var summary: String? = nil                 // AI-written 1-2 sentence personality blurb

    var adventure: Double = 0.5
    var nature: Double = 0.5
    var beaches: Double = 0.5
    var luxury: Double = 0.5
    var culture: Double = 0.5
    var history: Double = 0.5
    var food: Double = 0.5
    var roadTrips: Double = 0.5
    var remoteDestinations: Double = 0.5
    var cities: Double = 0.5

    var crowdTolerance: Double = 0.5            // 0 = avoid crowds, 1 = loves them
    var physicalDifficulty: Double = 0.5         // 0 = easy, 1 = strenuous

    var budgetLevel: BudgetLevel = .moderate
    var typicalTripLengthDays: Int = 7
    var preferredCompanions: [String] = []
    var homeRegion: HomeRegion? = nil

    var preferredClimates: [String] = []
    var avoidedActivities: [String] = []

    var visitedDestinationIDs: [UUID] = []
    var savedDestinationIDs: [UUID] = []
    var rejectedDestinationIDs: [UUID] = []

    /// Nudges a category score after a user save/reject signal. Clamps to 0...1.
    mutating func reinforce(category: TravelCategory, positive: Bool, step: Double = 0.05) {
        let delta = positive ? step : -step
        switch category {
        case .adventure:  adventure = (adventure + delta).clamped()
        case .nature:     nature = (nature + delta).clamped()
        case .beaches:    beaches = (beaches + delta).clamped()
        case .luxury:     luxury = (luxury + delta).clamped()
        case .culture:    culture = (culture + delta).clamped()
        case .history:    history = (history + delta).clamped()
        case .food:       food = (food + delta).clamped()
        case .roadTrips:  roadTrips = (roadTrips + delta).clamped()
        case .remote:     remoteDestinations = (remoteDestinations + delta).clamped()
        case .cities:     cities = (cities + delta).clamped()
        case .mountains:  adventure = (adventure + delta).clamped()   // mountain trips drive adventure signal
        case .unique:     nature = (nature + delta).clamped()          // unique destinations are mostly natural phenomena
        case .wellness:   luxury = (luxury + delta).clamped()          // wellness preference tracks with luxury comfort
        }
    }
}

private extension Double {
    func clamped() -> Double { min(1.0, max(0.0, self)) }
}
