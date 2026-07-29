import Foundation

enum ProfileStore {
    private static let profileKey    = "travelProfile_v1"
    private static let onboardingKey = "hasCompletedOnboarding"

    static func save(_ profile: TravelProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    static func load() -> TravelProfile? {
        guard
            let data    = UserDefaults.standard.data(forKey: profileKey),
            let profile = try? JSONDecoder().decode(TravelProfile.self, from: data)
        else { return nil }
        return profile
    }

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }
}
