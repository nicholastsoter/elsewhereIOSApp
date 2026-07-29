import Foundation

// MARK: - Distance-based flight cost estimator
//
// Replaces DestinationLoader's origin-blind flat multipliers (1.5× / 2.5×) with
// distance-tier multipliers keyed to the user's home region.
//
// Distance thresholds and representative routes:
//   < 1,500 km   → short-haul        LAX→SFO, LHR→CDG, SYD→MEL
//   1,500–4,500  → medium-haul       NYC→LAX, PAR→CAI, NRT→SIN
//   4,500–9,000  → long-haul near    NYC→LHR, LAX→NRT, SYD→HKG
//   9,000–14,000 → long-haul far     NYC→SCL, LAX→DXB, LHR→MEL
//   > 14,000     → ultra-long-haul   JFK→SYD, LAX→JNB, LHR→SCL
//
// The base unit is recovered from costEstimate.lodgingLow, which DestinationLoader
// sets to cost_level × 100 × 1.0 — so lodgingLow == base exactly.
//
// isLive stays false — these are still labeled "ESTIMATED" in the UI.

enum CostEstimator {

    // MARK: - Distance tier

    enum DistanceTier {
        case shortHaul, mediumHaul, longHaulNear, longHaulFar, ultraLongHaul

        // Low-end flight cost = base × this multiplier
        var lowMultiplier: Double {
            switch self {
            case .shortHaul:     return 0.30
            case .mediumHaul:    return 0.70
            case .longHaulNear:  return 1.50   // matches the origin-blind baseline
            case .longHaulFar:   return 2.20
            case .ultraLongHaul: return 3.00
            }
        }

        // High-end flight cost = base × this multiplier
        var highMultiplier: Double {
            switch self {
            case .shortHaul:     return 0.70
            case .mediumHaul:    return 1.30
            case .longHaulNear:  return 2.50   // matches the origin-blind baseline
            case .longHaulFar:   return 3.50
            case .ultraLongHaul: return 4.80
            }
        }
    }

    // MARK: - Public API

    /// Updates flightsLow / flightsHigh for every destination based on the user's
    /// home region. All other cost fields (lodging, food, etc.) are unchanged.
    static func applyFlightCosts(homeRegion: HomeRegion, to destinations: [Destination]) -> [Destination] {
        let (homeLat, homeLon) = homeRegion.coordinate
        return destinations.map { d -> Destination in
            var updated = d
            let km   = haversineKm(lat1: homeLat, lon1: homeLon, lat2: d.latitude, lon2: d.longitude)
            let tier = tier(for: km)
            let base = baseCost(from: d.costEstimate)
            updated.costEstimate.flightsLow  = (base * tier.lowMultiplier).rounded()
            updated.costEstimate.flightsHigh = (base * tier.highMultiplier).rounded()
            return updated
        }
    }

    // MARK: - Helpers

    static func tier(for km: Double) -> DistanceTier {
        if km < 1_500  { return .shortHaul }
        if km < 4_500  { return .mediumHaul }
        if km < 9_000  { return .longHaulNear }
        if km < 14_000 { return .longHaulFar }
        return .ultraLongHaul
    }

    static func distanceKm(from homeRegion: HomeRegion, to destination: Destination) -> Double {
        let (lat, lon) = homeRegion.coordinate
        return haversineKm(lat1: lat, lon1: lon, lat2: destination.latitude, lon2: destination.longitude)
    }

    // lodgingLow = cost_level × 100 × 1.0 (see DestinationLoader.mapCost),
    // so recovering base is a direct read. Guards against manual MockData values
    // that don't follow this formula by falling back to $500 if lodgingLow is 0.
    private static func baseCost(from estimate: CostEstimate) -> Double {
        estimate.lodgingLow > 0 ? estimate.lodgingLow : 500
    }

    private static func haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R    = 6_371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a    = sin(dLat / 2) * sin(dLat / 2)
                 + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
                 * sin(dLon / 2) * sin(dLon / 2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
