import Foundation

/// Abstraction so the app is never hard-wired to one image vendor.
/// Swap MockImageProvider for UnsplashImageProvider / PexelsImageProvider later
/// without touching any view code.
protocol ImageProvider {
    func searchImages(query: String, limit: Int) async throws -> [DestinationImage]
    func fetchDestinationImages(destination: String, region: String) async throws -> [DestinationImage]
    func attribution(for image: DestinationImage) -> String
}

struct MockImageProvider: ImageProvider {
    // Free-to-use placeholder photo IDs (picsum.photos) so previews render real images.
    private let seeds = ["1015", "1018", "1021", "1025", "1035", "1043", "1051", "1062"]

    func searchImages(query: String, limit: Int) async throws -> [DestinationImage] {
        (0..<limit).map { i in
            let seed = seeds[i % seeds.count]
            return DestinationImage(
                id: "\(query)-\(seed)-\(i)",
                url: URL(string: "https://picsum.photos/id/\(seed)/1200/1600")!,
                thumbnailURL: URL(string: "https://picsum.photos/id/\(seed)/300/400")!,
                width: i % 2 == 0 ? 1600 : 1200,
                height: i % 2 == 0 ? 1200 : 1600,
                photographer: "Mock Photographer",
                provider: "mock",
                attributionURL: URL(string: "https://picsum.photos"),
                licenseNote: "Placeholder — replace with licensed provider",
                tags: [query]
            )
        }
    }

    func fetchDestinationImages(destination: String, region: String) async throws -> [DestinationImage] {
        try await searchImages(query: "\(destination) \(region)", limit: 4)
    }

    func attribution(for image: DestinationImage) -> String {
        "Photo via \(image.provider) — \(image.photographer)"
    }
}
