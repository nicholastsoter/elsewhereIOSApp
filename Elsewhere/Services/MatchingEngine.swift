import Foundation

// MARK: - Matching Engine
// Computes match scores and generates templated explanation text for each destination.
//
// Stand-in for future AI-generated personalization. When ready to swap:
//   1. Replace `explanation(profile:destination:)` with an async Claude API call.
//   2. Keep `matchScore(profile:destination:)` — it can remain a local heuristic used
//      for sorting even after AI explanations are live.
//   3. The (text, anchors) return contract should stay stable so WhyLoveItSection
//      and DestinationCardView don't need changes.

enum MatchingEngine {

    // MARK: - Public API

    /// Produces a 0–100 integer match score for a single destination.
    ///
    /// Weights:
    ///   - Category affinity:    50%
    ///   - Difficulty match:     20%
    ///   - Crowd match:          15%
    ///   - Budget match:         15%
    static func matchScore(profile: TravelProfile, destination: Destination) -> Int {
        let cat    = categoryScore(profile: profile, categories: destination.categories)
        let diff   = difficultyScore(userLevel: profile.physicalDifficulty, dest: destination.difficulty)
        let crowd  = crowdScore(tolerance: profile.crowdTolerance, level: destination.crowdLevel)
        let budget = budgetScore(userBudget: profile.budgetLevel, destTier: destination.costTier)

        let raw = 0.50 * cat + 0.20 * diff + 0.15 * crowd + 0.15 * budget
        return min(99, max(1, Int((raw * 100).rounded())))
    }

    /// Returns a (text, anchors) tuple for the "Why You Might Love It" section.
    /// Text is templated from the user's top 1–2 matching traits — not generic.
    static func explanation(
        profile: TravelProfile,
        destination: Destination
    ) -> (text: String, anchors: [String]) {
        let template = selectTemplate(profile: profile, destination: destination)
        return render(template: template, profile: profile, destination: destination)
    }

    /// Applies match scores + explanations to an array of destinations and sorts by score.
    static func apply(profile: TravelProfile, to destinations: [Destination]) -> [Destination] {
        var result = destinations.map { d -> Destination in
            var updated = d
            updated.matchScore = matchScore(profile: profile, destination: d)
            let (text, anchors) = explanation(profile: profile, destination: d)
            updated.personalizedExplanation = text
            updated.explanationAnchors = anchors
            return updated
        }
        result.sort { ($0.matchScore ?? 0) > ($1.matchScore ?? 0) }
        return result
    }

    // MARK: - Category score

    // Primary category is weighted 1.0, secondary 0.6, tertiary 0.35, etc.
    // This gives the destination's main character the most influence.
    private static func categoryScore(profile: TravelProfile, categories: [TravelCategory]) -> Double {
        guard !categories.isEmpty else { return 0.3 }
        let weights: [Double] = [1.0, 0.6, 0.35, 0.2, 0.15]
        var weightedSum = 0.0
        var totalWeight = 0.0
        for (i, cat) in categories.prefix(5).enumerated() {
            let w = weights[min(i, weights.count - 1)]
            weightedSum += userScore(for: cat, profile: profile) * w
            totalWeight += w
        }
        return totalWeight > 0 ? weightedSum / totalWeight : 0.3
    }

    static func userScore(for category: TravelCategory, profile: TravelProfile) -> Double {
        switch category {
        case .adventure:  return profile.adventure
        case .nature:     return profile.nature
        case .beaches:    return profile.beaches
        case .luxury:     return profile.luxury
        case .culture:    return profile.culture
        case .history:    return profile.history
        case .food:       return profile.food
        case .roadTrips:  return profile.roadTrips
        case .remote:     return profile.remoteDestinations
        case .cities:     return profile.cities
        case .mountains:  return profile.adventure
        case .unique:     return profile.nature
        case .wellness:   return profile.luxury
        }
    }

    // MARK: - Difficulty score

    // physicalDifficulty 0–1 maps to 4 buckets; score decays steeply if off by 2+ levels.
    private static func difficultyScore(userLevel: Double, dest: DifficultyLevel) -> Double {
        let u: Int
        if userLevel < 0.35 { u = 0 }
        else if userLevel < 0.60 { u = 1 }
        else if userLevel < 0.80 { u = 2 }
        else { u = 3 }

        let d: Int
        switch dest {
        case .easy:        d = 0
        case .moderate:    d = 1
        case .challenging: d = 2
        case .strenuous:   d = 3
        }

        switch abs(u - d) {
        case 0:  return 1.00
        case 1:  return 0.60
        case 2:  return 0.20
        default: return 0.05
        }
    }

    // MARK: - Crowd score

    // Maps crowd levels to numeric positions; smaller distance = better match.
    private static func crowdScore(tolerance: Double, level: CrowdLevel) -> Double {
        let destVal: Double
        switch level {
        case .low:      destVal = 0.15
        case .moderate: destVal = 0.50
        case .high:     destVal = 0.90
        }
        return max(0, 1.0 - abs(tolerance - destVal))
    }

    // MARK: - Budget score

    private static func budgetScore(userBudget: BudgetLevel, destTier: CostTier) -> Double {
        let u: Double
        switch userBudget {
        case .shoestring:  u = 0.10
        case .moderate:    u = 0.40
        case .comfortable: u = 0.70
        case .luxury:      u = 0.95
        }
        let d: Double
        switch destTier {
        case .budget:   d = 0.10
        case .moderate: d = 0.40
        case .premium:  d = 0.70
        case .luxury:   d = 0.95
        }
        return max(0, 1.0 - abs(u - d))
    }

    // MARK: - Template selection

    private enum Template {
        case remoteAndLowCrowd
        case adventureAndRemote
        case adventureAndStrenuous
        case natureAndRemote
        case cultureAndHistory
        case cultureAndFood
        case foodAndCities
        case beachesAndLuxury
        case beachesAndLowCrowd
        case roadTripsAndNature
        case luxuryAndLowCrowd
        case generic
    }

    private static let threshold: Double = 0.65

    private static func selectTemplate(profile: TravelProfile, destination: Destination) -> Template {
        let cats = destination.categories
        let t    = threshold

        let isRemote    = profile.remoteDestinations > t && cats.contains(.remote)
        let isAdventure = profile.adventure > t && (cats.contains(.adventure) || cats.contains(.mountains))
        let isNature    = profile.nature > t && (cats.contains(.nature) || cats.contains(.unique))
        let isCulture   = profile.culture > t && cats.contains(.culture)
        let isHistory   = profile.history > t && cats.contains(.history)
        let isFood      = profile.food > t && cats.contains(.food)
        let isBeaches   = profile.beaches > t && cats.contains(.beaches)
        let isLuxury    = profile.luxury > t && (cats.contains(.luxury) || cats.contains(.wellness))
        let isRoadTrips = profile.roadTrips > t && cats.contains(.roadTrips)
        let isCities    = profile.cities > t && cats.contains(.cities)
        let lowCrowd    = profile.crowdTolerance < 0.4 && destination.crowdLevel == .low
        let strenuous   = profile.physicalDifficulty > 0.65 && (destination.difficulty == .strenuous || destination.difficulty == .challenging)

        if isRemote && lowCrowd      { return .remoteAndLowCrowd }
        if isAdventure && isRemote   { return .adventureAndRemote }
        if isAdventure && strenuous  { return .adventureAndStrenuous }
        if isNature && isRemote      { return .natureAndRemote }
        if isCulture && isHistory    { return .cultureAndHistory }
        if isCulture && isFood       { return .cultureAndFood }
        if isFood && isCities        { return .foodAndCities }
        if isBeaches && isLuxury     { return .beachesAndLuxury }
        if isBeaches && lowCrowd     { return .beachesAndLowCrowd }
        if isRoadTrips && isNature   { return .roadTripsAndNature }
        if isLuxury && lowCrowd      { return .luxuryAndLowCrowd }
        return .generic
    }

    // MARK: - Template rendering

    private static func render(
        template: Template,
        profile: TravelProfile,
        destination: Destination
    ) -> (text: String, anchors: [String]) {
        let n    = destination.name
        let cty  = destination.country
        let reg  = destination.region
        let a1   = destination.activities.first.map { lc($0) } ?? "exploring the area"
        let a2   = destination.activities.dropFirst().first.map { lc($0) } ?? a1
        let pair = a1 != a2 ? "\(a1) and \(a2)" : a1
        let kp   = keyPhrase(destination.summary)
        let v    = abs(destination.id.hashValue) % 8

        switch template {
        case .remoteAndLowCrowd:
            let anchors = ["Remote: \(pct(profile.remoteDestinations))", "Crowd tolerance: \(pct(profile.crowdTolerance))", "Crowd level: \(destination.crowdLevel.rawValue)"]
            switch v {
            case 0:  return ("You score high on remote destinations and low on crowd tolerance. \(n) sits in \(cty) — \(kp) — and stays genuinely quiet because of it.", anchors)
            case 1:  return ("Low crowd tolerance and a pull toward remote terrain define your profile. \(n) delivers both: \(a1) is the main draw, and it doesn't attract mass tourism.", anchors)
            case 2:  return ("Your profile consistently picks remote over accessible, and quiet over busy. \(n) in \(reg) is exactly that — \(pair), away from the tourist track.", anchors)
            case 3:  return ("You tend toward places that take effort to reach and don't share well with crowds. \(n) in \(cty) fits: \(a1) is the draw, and the headcount reflects how hard it is to get there.", anchors)
            case 4:  return ("Remote and quiet is where your profile peaks. \(n) scores on both — \(kp), and the infrastructure has never been built up enough to change that.", anchors)
            case 5:  return ("\(n) in \(reg) is the kind of place your profile is optimized for: genuinely remote, genuinely uncrowded, with \(a1) as the primary reason to go.", anchors)
            case 6:  return ("Most places as good as \(n) eventually get discovered. This one stays quiet because \(a1) filters out the casual visitors your profile is designed to avoid.", anchors)
            default: return ("Your two clearest profile signals — remote destinations and low crowd tolerance — both point to \(n). \(uc(kp)), and it shows.", anchors)
            }
        case .adventureAndRemote:
            let anchors = ["Adventure: \(pct(profile.adventure))", "Remote: \(pct(profile.remoteDestinations))"]
            switch v {
            case 0:  return ("Adventure and remote destinations are your two highest-scoring interests. \(n) hits both — \(a1) in terrain that takes real effort to reach.", anchors)
            case 1:  return ("You're drawn to active, off-the-beaten-path experiences. \(n) in \(cty) rewards that: \(pair) in a setting that hasn't been smoothed out for mass tourism.", anchors)
            case 2:  return ("Remote adventure travel is where your profile peaks. \(n) is the version of \(cty) most visitors never see — \(a1) is how you get there.", anchors)
            case 3:  return ("Your profile scores adventure and remote destinations near the top. \(n) is built around \(a1) — exactly the kind of trip your numbers are optimized for.", anchors)
            case 4:  return ("Adventure and remoteness together are your strongest profile signal. \(n) in \(reg) delivers — \(kp), and it takes real commitment to get there.", anchors)
            case 5:  return ("You score high on both adventure and remote destinations. \(n) in \(cty) is the version of that combination where \(a1) is the whole point of the trip.", anchors)
            case 6:  return ("Remote and active is a rare combination that most destinations only partially deliver. \(n) in \(cty) covers both: \(pair) in terrain that hasn't been packaged for mass tourism.", anchors)
            default: return ("\(n) is the kind of place that rewards your profile exactly: \(kp), remote enough to require real planning, and built around \(a1).", anchors)
            }
        case .adventureAndStrenuous:
            let anchors = ["Adventure: \(pct(profile.adventure))", "Physical level: \(pct(profile.physicalDifficulty))"]
            switch v {
            case 0:  return ("Your profile leans toward physically demanding, active travel. \(n) is built around \(a1) — the kind of effort that makes a trip feel earned.", anchors)
            case 1:  return ("You're willing to push physically and prefer active over resort-style travel. \(n) in \(cty) rewards that: \(pair) aren't passive experiences.", anchors)
            case 2:  return ("Physically challenging, self-directed travel is near the top of your profile. \(n) delivers — \(a1) is the main draw, and it doesn't hold back.", anchors)
            case 3:  return ("Your profile scores high on adventure and physical difficulty. \(n) filters out casual visitors: \(kp), and the effort is the whole point.", anchors)
            case 4:  return ("High physical difficulty and active travel define your profile. \(n) in \(reg) is a direct match — \(a1) is what the trip is made of.", anchors)
            case 5:  return ("You prefer trips where the physical effort is the experience, not an obstacle to it. \(n) in \(cty) delivers exactly that: \(pair) at the level your profile is looking for.", anchors)
            case 6:  return ("Your profile reads as someone who doesn't want the trip handed to them. \(n) is the right fit — \(kp), and \(a1) is how the serious visitors engage with it.", anchors)
            default: return ("Adventure and physical challenge are near the top of your travel interests. \(n) in \(cty) is built for exactly that: \(a1) in terrain that earns its difficulty.", anchors)
            }
        case .natureAndRemote:
            let anchors = ["Nature: \(pct(profile.nature))", "Remote: \(pct(profile.remoteDestinations))"]
            switch v {
            case 0:  return ("Remote natural landscapes are near the top of your profile. \(n) offers that in a form that's hard to find: \(kp).", anchors)
            case 1:  return ("You score high on nature and consistently prefer destinations away from crowds. \(n) in \(cty) fits — \(a1) in terrain that stays genuinely wild.", anchors)
            case 2:  return ("Natural, remote environments are where your profile peaks. \(n) is one of the places where the landscape itself is the draw: \(a1) is how you access it.", anchors)
            case 3:  return ("Your strongest interests are nature and remote destinations. \(n) is known for exactly that — \(pair) in one of the less-visited corners of \(cty).", anchors)
            case 4:  return ("Wild, remote landscapes are what your profile is most consistently drawn to. \(n) in \(reg) delivers — \(kp), and it stays that way because of how hard it is to reach.", anchors)
            case 5:  return ("You score high on nature and low on tourist density. \(n) in \(cty) hits both: \(pair) in a setting that the infrastructure hasn't caught up with yet.", anchors)
            case 6:  return ("Remote nature travel requires places that haven't been made easy to visit. \(n) in \(cty) qualifies — \(kp), and \(a1) is how most people who make it there spend their time.", anchors)
            default: return ("Your profile is clearest when it comes to nature and remote destinations. \(n) delivers on both: \(a1) in \(reg) with the kind of access that keeps the crowds at bay.", anchors)
            }
        case .cultureAndHistory:
            let anchors = ["Culture: \(pct(profile.culture))", "History: \(pct(profile.history))"]
            switch v {
            case 0:  return ("Culture and history are your two strongest travel interests. \(n) in \(cty) layers both — \(a1) is one way in, and the context goes back centuries.", anchors)
            case 1:  return ("Your profile is weighted toward culture and history. \(n) rewards exactly that kind of attention: \(kp).", anchors)
            case 2:  return ("Culture and history rank at the top of your travel interests. \(n) has been building on both for a long time — \(pair) are two ways to engage seriously.", anchors)
            case 3:  return ("Your strongest interests — culture and history — are exactly what \(n) in \(cty) is known for. \(uc(a1)) is a good place to start.", anchors)
            case 4:  return ("You score high on culture and history. \(n) in \(reg) rewards slow, attentive travel: \(kp), and \(a1) is the kind of thing that takes time to do properly.", anchors)
            case 5:  return ("Culture and history together score highest in your profile. \(n) in \(cty) has both in depth — \(pair) are two ways to access what makes it worth the trip.", anchors)
            case 6:  return ("Your travel interests peak at culture and history. \(n) is the kind of place where those two things are the same thing — \(kp), accumulated over centuries.", anchors)
            default: return ("Few places match your profile on both culture and history as cleanly as \(n) in \(cty). \(uc(a1)) is one way in; the depth behind it is what keeps people there.", anchors)
            }
        case .cultureAndFood:
            let anchors = ["Culture: \(pct(profile.culture))", "Food: \(pct(profile.food))"]
            switch v {
            case 0:  return ("Your profile is weighted toward culture and food. \(n) is the kind of place where both show up in \(pair) — not just in restaurants.", anchors)
            case 1:  return ("Culture and food are your two strongest travel interests. \(n) in \(cty) earns high marks on both: \(kp).", anchors)
            case 2:  return ("You score high on culture and food travel. \(n) delivers — \(a1) is one of the entry points, and the cultural texture is consistent throughout.", anchors)
            case 3:  return ("Your travel interests peak at culture and food. In \(n), those two things are inseparable — \(a1) is as much cultural as culinary.", anchors)
            case 4:  return ("Culture and food together are your clearest profile signals. \(n) in \(reg) is strong on both — \(kp), and \(a1) is one of the ways the culture and the food show up in the same place.", anchors)
            case 5:  return ("You score high on culture and food. \(n) in \(cty) is a place where neither one substitutes for the other — \(pair) are two different angles into the same experience.", anchors)
            case 6:  return ("Your profile peaks where culture and food overlap. \(n) in \(cty) is a strong match: \(a1) isn't just eating, it's the clearest expression of \(kp).", anchors)
            default: return ("Food and culture are inseparable in \(n) — and your profile is built for exactly that. \(uc(a1)) is how most people start to understand both.", anchors)
            }
        case .foodAndCities:
            let anchors = ["Food: \(pct(profile.food))", "Cities: \(pct(profile.cities))"]
            switch v {
            case 0:  return ("You're drawn to city life and food travel. \(n) punches above its size on both — \(a1) is one of the draws, and the food scene is a reason to go on its own.", anchors)
            case 1:  return ("Food and cities are your top interests. \(n) scores high on both: \(kp).", anchors)
            case 2:  return ("Your profile peaks at food and urban environments. \(n) in \(cty) delivers — \(pair) give a sense of the range.", anchors)
            case 3:  return ("You score high on cities and food. \(n) is the kind of place where eating well is the main event — \(a1) is how most people find their footing.", anchors)
            case 4:  return ("City travel and food are your two strongest interests. \(n) in \(reg) earns on both — \(kp), and \(a1) is the part that's hardest to replicate elsewhere.", anchors)
            case 5:  return ("Your profile scores cities and food near the top. \(n) in \(cty) is a match: the city delivers on density and texture, and \(a1) is one of the main reasons to go.", anchors)
            case 6:  return ("Food-first city travel is what your profile is optimized for. \(n) in \(cty) covers that well: \(pair) are two of the draws, and neither requires a tourist-trail mindset.", anchors)
            default: return ("\(n) in \(cty) is the kind of city your profile is built for — \(kp), with a food scene that rewards the approach your numbers suggest.", anchors)
            }
        case .beachesAndLuxury:
            let anchors = ["Beaches: \(pct(profile.beaches))", "Luxury: \(pct(profile.luxury))"]
            switch v {
            case 0:  return ("You score high on beaches and prefer comfortable travel. \(n) in \(cty) is built for exactly that: \(kp).", anchors)
            case 1:  return ("Beaches and luxury are your top two interests. \(n) delivers both — \(pair) at a quality level that matches your budget preference.", anchors)
            case 2:  return ("Your profile peaks at beaches and comfort. \(n) in \(reg) is a clean expression of both — \(a1) is the main draw, and the quality holds up.", anchors)
            case 3:  return ("You score high on beaches and prefer higher-end travel. \(n) does both well: \(kp).", anchors)
            case 4:  return ("Beaches and luxury together score highest in your profile. \(n) in \(cty) is the right combination — \(a1) without the quality compromise that most beach destinations make.", anchors)
            case 5:  return ("You prefer beaches with a high-quality, comfortable experience. \(n) in \(reg) delivers: \(kp), and \(a1) is the kind of activity that fits the level your budget preference suggests.", anchors)
            case 6:  return ("Your profile is clear on two things: beaches and comfort. \(n) in \(cty) covers both — \(pair) in a setting that holds up to the higher end of your expectations.", anchors)
            default: return ("High-quality beach travel is what your profile points toward. \(n) in \(cty) is one of the cleaner expressions of that: \(kp), with \(a1) as one of the main draws.", anchors)
            }
        case .beachesAndLowCrowd:
            let anchors = ["Beaches: \(pct(profile.beaches))", "Crowd tolerance: \(pct(profile.crowdTolerance))", "Crowd level: \(destination.crowdLevel.rawValue)"]
            switch v {
            case 0:  return ("You love beaches but prefer them quiet. \(n) in \(cty) fits — \(a1) requires enough effort that the headcount stays down.", anchors)
            case 1:  return ("Beaches rank high in your profile, and you'd rather have them to yourself. \(n) delivers: \(kp), away from the package-tour crowd.", anchors)
            case 2:  return ("Your profile scores high on beaches and low on crowd tolerance. \(n) in \(reg) doesn't compromise on either — \(a1) is how most visitors find it.", anchors)
            case 3:  return ("You prefer beaches that haven't been overrun. \(n) in \(cty) earns points on both counts — \(pair) with crowd levels that reflect its relative obscurity.", anchors)
            case 4:  return ("Beaches and low crowds are your two clearest signals. \(n) in \(reg) delivers both — \(kp), and the access keeps the volume down.", anchors)
            case 5:  return ("You score high on beaches and prefer them quiet. \(n) in \(cty) is the version of that combination that actually delivers: \(a1) without the resort-strip density.", anchors)
            case 6:  return ("Finding a good beach without crowds usually requires a trade-off. \(n) in \(cty) is one of the places that doesn't ask for one — \(pair) in a setting that stays quiet because of where it is.", anchors)
            default: return ("Your beach preference and crowd tolerance together point to \(n) in \(reg): \(kp), and the logistics of getting there are what keep it that way.", anchors)
            }
        case .roadTripsAndNature:
            let anchors = ["Road trips: \(pct(profile.roadTrips))", "Nature: \(pct(profile.nature))"]
            switch v {
            case 0:  return ("Road trips through dramatic landscapes rank at the top of your profile. \(n) is one of the world's great drives: \(kp).", anchors)
            case 1:  return ("You score high on road trips and dramatic natural scenery. \(n) in \(cty) delivers both — the route takes in \(pair), none of it forgettable.", anchors)
            case 2:  return ("Road trips and nature are your two strongest travel interests. \(n) is built around them: \(kp).", anchors)
            case 3:  return ("Your profile peaks at road trips and natural landscapes. \(n) in \(reg) earns that — \(pair) are the main draws along the route.", anchors)
            case 4:  return ("The combination of road trips and natural scenery scores highest in your profile. \(n) in \(cty) covers both: \(a1) and the kind of landscape that rewards driving slowly.", anchors)
            case 5:  return ("You prefer road trips where the landscape is the destination. \(n) in \(reg) is built for that — \(kp), and \(a1) is the draw that slows you down in the right places.", anchors)
            case 6:  return ("Road trips and dramatic nature together define your travel profile. \(n) in \(cty) is one of the routes where those two things converge: \(pair) along a drive that earns its reputation.", anchors)
            default: return ("Your profile is clearest on road trips through natural landscapes. \(n) in \(reg) delivers — \(kp), with \(a1) as one of the main reasons to take it slow.", anchors)
            }
        case .luxuryAndLowCrowd:
            let anchors = ["Luxury: \(pct(profile.luxury))", "Crowd tolerance: \(pct(profile.crowdTolerance))"]
            switch v {
            case 0:  return ("You prefer comfortable travel and tend to avoid busy places. \(n) in \(cty) is the quieter, higher-end version of its region — \(a1) without the crowds.", anchors)
            case 1:  return ("Luxury and low crowd tolerance are your two strongest signals. \(n) delivers both: \(kp), and it doesn't draw the same volume as its neighbors.", anchors)
            case 2:  return ("Your profile scores high on comfort and low on crowd tolerance. \(n) in \(cty) is a good fit — \(a1) at a quality level that matches your budget preference, without the tourist-trail density.", anchors)
            case 3:  return ("You prefer comfortable, quiet travel. \(n) in \(reg) is the easier-to-breathe version of the area — \(a1) is one of the main draws, and it stays that way.", anchors)
            case 4:  return ("Comfort and low crowds together score highest in your profile. \(n) in \(cty) delivers — \(kp), and the quality holds up without the volume that comparable destinations attract.", anchors)
            case 5:  return ("You score high on luxury and low on crowd tolerance. \(n) in \(reg) is the right combination: \(a1) at a level that fits your budget preference, in a place that hasn't been overrun.", anchors)
            case 6:  return ("High-quality, quiet travel is what your profile points toward. \(n) in \(cty) is one of the cleaner expressions of that — \(pair) without the crowd density that usually comes with destinations at this level.", anchors)
            default: return ("Your profile is built for comfort without compromise on crowd tolerance. \(n) in \(cty) delivers: \(kp), and \(a1) is the kind of experience that holds up at the quality level your budget preference suggests.", anchors)
            }
        case .generic:
            let topCats = topMatchingCategories(profile: profile, destination: destination, limit: 2)
            if topCats.isEmpty { return (destination.summary, []) }
            let names   = topCats.map(\.label).joined(separator: " and ")
            let anchors = topCats.map { "\($0.label): \(pct(userScore(for: $0, profile: profile)))" }
            switch v {
            case 0:  return ("Your top interests — \(names) — align with what \(n) does best. \(uc(a1)) is one of the main draws.", anchors)
            case 1:  return ("Your strongest interests point toward \(names), and \(n) in \(cty) delivers: \(a1) is one of the main draws.", anchors)
            case 2:  return ("\(n) in \(cty) scores well against your profile. Your top interests — \(names) — are exactly what it's known for: \(kp).", anchors)
            case 3:  return ("Your profile peaks at \(names). \(n) delivers — \(pair) are the main entry points for exactly that kind of trip.", anchors)
            case 4:  return ("\(names) score highest in your profile, and \(n) in \(reg) is a direct match: \(kp).", anchors)
            case 5:  return ("Your travel interests point clearly toward \(names). \(n) in \(cty) covers that well — \(a1) is one of the main reasons people go.", anchors)
            case 6:  return ("\(n) in \(cty) earns well against your top interests — \(names) — and \(a1) is one of the draws that makes the case.", anchors)
            default: return ("Your profile is clearest on \(names), and \(n) in \(reg) is a strong match: \(kp), with \(a1) as one of the main entry points.", anchors)
            }
        }
    }

    private static func topMatchingCategories(
        profile: TravelProfile,
        destination: Destination,
        limit: Int
    ) -> [TravelCategory] {
        Array(
            destination.categories
                .sorted { userScore(for: $0, profile: profile) > userScore(for: $1, profile: profile) }
                .prefix(limit)
                .filter { userScore(for: $0, profile: profile) > 0.4 }
        )
    }

    // MARK: - Render helpers

    private static func lc(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.lowercased() + String(s.dropFirst())
    }

    private static func uc(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + String(s.dropFirst())
    }

    // Pull the first clause (up to the first comma, period, or dash) as a lowercase
    // characteristic phrase for mid-sentence use. Falls back to a truncated summary.
    private static func keyPhrase(_ summary: String) -> String {
        let stops = CharacterSet(charactersIn: ".,;—–")
        if let range = summary.rangeOfCharacter(from: stops) {
            let phrase = String(summary[summary.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            if phrase.count >= 15 { return phrase.lowercased() }
        }
        let truncated = summary.count > 80 ? String(summary.prefix(80)) : summary
        return truncated.lowercased()
    }

    private static func pct(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
