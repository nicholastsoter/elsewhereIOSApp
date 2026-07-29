import SwiftUI

/// Central design tokens for Elsewhere. Keep all color/type/spacing decisions
/// here so the visual language stays consistent as the app grows.
enum ElsewhereTheme {

    enum Color {
        static let ink = SwiftUI.Color(hex: "0E2A3B")          // deep navy, primary dark surface
        static let sand = SwiftUI.Color(hex: "F7F3EC")         // warm off-white
        static let dune = SwiftUI.Color(hex: "DDD6C8")         // muted neutral
        static let sunset = SwiftUI.Color(hex: "F4A259")       // accent / match-score highlight
        static let palm = SwiftUI.Color(hex: "2E7D5B")         // secondary accent, success
        static let teal = SwiftUI.Color(hex: "1C4A5E")         // mid-tone surface
        static let bark = SwiftUI.Color(hex: "5B3A29")         // shadow / grounding tone

        static let cardBackground = SwiftUI.Color(hex: "FFFFFF")
        static let subtleText = SwiftUI.Color(hex: "6B7280")
    }

    enum Font {
        static func display(_ size: CGFloat = 34) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .serif)
        }
        static func title(_ size: CGFloat = 22) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func caption(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 24
        static let pill: CGFloat = 100
        static let small: CGFloat = 12
    }
}

extension SwiftUI.Color {
    /// Convenience initializer for hex strings like "0E2A3B" (no leading #).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Reusable match-score pill shown on destination cards and detail screens.
struct MatchBadge: View {
    let percent: Int

    var body: some View {
        Text("\(percent)% MATCH")
            .font(ElsewhereTheme.Font.caption(12))
            .foregroundStyle(ElsewhereTheme.Color.ink)
            .padding(.horizontal, ElsewhereTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(ElsewhereTheme.Color.sunset)
            .clipShape(Capsule())
    }
}

/// Skeleton placeholder used while destination images/data are loading.
struct SkeletonView: View {
    var cornerRadius: CGFloat = ElsewhereTheme.Radius.card
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ElsewhereTheme.Color.dune.opacity(animate ? 0.4 : 0.7))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}
