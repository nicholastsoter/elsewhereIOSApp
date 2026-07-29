import Foundation

// MARK: - Pipeline JSON DTOs

private struct PipelineDestination: Decodable {
    let id: String?
    let name: String
    let country: String
    let region: String
    let latitude: Double
    let longitude: Double
    let primaryCategory: String?
    let categories: [String]
    let difficulty: Int
    let crowdLevel: Int
    let costLevel: Int
    let idealTripDays: [Int]
    let bestMonths: [Int]
    let popularity: String?
    let description: String
    let activities: [String]
    let images: [PipelineImage]?

    enum CodingKeys: String, CodingKey {
        case id, name, country, region, latitude, longitude
        case primaryCategory  = "primary_category"
        case categories, difficulty
        case crowdLevel       = "crowd_level"
        case costLevel        = "cost_level"
        case idealTripDays    = "ideal_trip_days"
        case bestMonths       = "best_months"
        case popularity, description, activities, images
    }
}

private struct PipelineImage: Decodable {
    let id: String?
    let url: String
    let thumbnailUrl: String?
    let photographer: String?
    let provider: String?
    let attributionUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, url, photographer, provider
        case thumbnailUrl   = "thumbnail_url"
        case attributionUrl = "attribution_url"
    }
}

// MARK: - Loader

@MainActor
enum DestinationLoader {
    static func loadAll() -> [Destination] {
        guard
            let fileURL = Bundle.main.url(forResource: "destinations_working", withExtension: "json"),
            let data    = try? Data(contentsOf: fileURL),
            let raw     = try? JSONDecoder().decode([PipelineDestination].self, from: data)
        else {
            assertionFailure("DestinationLoader: destinations_working.json missing from bundle")
            return []
        }
        return raw.map(map(_:))
    }

    // MARK: Destination mapping

    private static func map(_ raw: PipelineDestination) -> Destination {
        let id      = UUID(uuidString: raw.id ?? "") ?? UUID()
        let tripMin = raw.idealTripDays.first ?? 5
        let tripMax = max(tripMin, raw.idealTripDays.last ?? tripMin)
        let images  = mapImages(raw.images ?? [])

        return Destination(
            id: id,
            name: raw.name,
            country: raw.country,
            region: raw.region,
            latitude: raw.latitude,
            longitude: raw.longitude,
            summary: raw.description,
            personalizedExplanation: nil,  // filled by matching engine, not pipeline
            explanationAnchors: [],
            matchScore: nil,               // filled by matching engine, not pipeline
            categories: mapCategories(raw.categories),
            activities: raw.activities,
            bestMonths: raw.bestMonths,
            recommendedTripLengthDays: tripMin...tripMax,
            costEstimate: mapCost(raw.costLevel),
            costTier: mapCostTier(raw.costLevel),
            difficulty: mapDifficulty(raw.difficulty),
            crowdLevel: mapCrowdLevel(raw.crowdLevel),
            heroImage: images.first,
            supportingImages: images.count > 1 ? Array(images.dropFirst()) : [],
            similarDestinationIDs: [],
            popularAttractions: [],
            sampleItinerary: [],
            saveStatus: nil
        )
    }

    // MARK: Category mapping
    // "unique"    → .nature    (unique-phenomena destinations are overwhelmingly natural)
    // "mountains" → .adventure (mountain destinations are primarily adventure-oriented)
    // "wellness"  → .luxury    (wellness/spa sits closest to the luxury tier)

    private static func mapCategories(_ raw: [String]) -> [TravelCategory] {
        var seen = Set<TravelCategory>()
        return raw.compactMap { string -> TravelCategory? in
            guard let cat = mapCategory(string), seen.insert(cat).inserted else { return nil }
            return cat
        }
    }

    private static func mapCategory(_ raw: String) -> TravelCategory? {
        switch raw {
        case "adventure":  return .adventure
        case "nature":     return .nature
        case "beaches":    return .beaches
        case "luxury":     return .luxury
        case "culture":    return .culture
        case "history":    return .history
        case "food":       return .food
        case "road_trips": return .roadTrips
        case "remote":     return .remote
        case "cities":     return .cities
        case "mountains":  return .mountains
        case "unique":     return .unique
        case "wellness":   return .wellness
        default:           return nil
        }
    }

    // MARK: Difficulty  (1–10 → enum)
    // 1–3 easy · 4–6 moderate · 7–8 challenging · 9–10 strenuous

    private static func mapDifficulty(_ score: Int) -> DifficultyLevel {
        switch score {
        case ...3:  return .easy
        case 4...6: return .moderate
        case 7...8: return .challenging
        default:    return .strenuous
        }
    }

    // MARK: Crowd level  (1–10 → enum)
    // 1–3 low · 4–6 moderate · 7–10 high

    private static func mapCrowdLevel(_ score: Int) -> CrowdLevel {
        switch score {
        case ...3:  return .low
        case 4...6: return .moderate
        default:    return .high
        }
    }

    // MARK: Cost estimation
    // cost_level × $100 as a rough per-person-per-week base unit.
    // isLive: false — placeholders until a real pricing API is wired in.

    private static func mapCost(_ level: Int) -> CostEstimate {
        let base = Double(max(1, min(10, level))) * 100.0
        return CostEstimate(
            flightsLow:         (base * 1.5).rounded(),
            flightsHigh:        (base * 2.5).rounded(),
            lodgingLow:         (base * 1.0).rounded(),
            lodgingHigh:        (base * 1.8).rounded(),
            foodLow:            (base * 0.5).rounded(),
            foodHigh:           (base * 0.8).rounded(),
            transportationLow:  (base * 0.3).rounded(),
            transportationHigh: (base * 0.6).rounded(),
            activitiesLow:      (base * 0.3).rounded(),
            activitiesHigh:     (base * 0.6).rounded(),
            isLive: false
        )
    }

    private static func mapCostTier(_ level: Int) -> CostTier {
        switch level {
        case ...3:  return .budget
        case 4...6: return .moderate
        case 7...8: return .premium
        default:    return .luxury
        }
    }

    // MARK: Images

    private static func mapImages(_ raw: [PipelineImage]) -> [DestinationImage] {
        raw.compactMap { img in
            guard let url = URL(string: img.url) else { return nil }
            return DestinationImage(
                id: img.id ?? UUID().uuidString,
                url: url,
                thumbnailURL: img.thumbnailUrl.flatMap(URL.init),
                width: 1200,
                height: 1600,
                photographer: img.photographer ?? "Unknown",
                provider: img.provider ?? "picsum",
                attributionURL: img.attributionUrl.flatMap(URL.init)
            )
        }
    }
}
