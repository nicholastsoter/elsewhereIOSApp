import SwiftUI

struct SplashView: View {
    let onDismiss: () -> Void
    var delay: TimeInterval = 0.6

    var body: some View {
        ZStack {
            ElsewhereTheme.Color.ink.ignoresSafeArea()

            VStack(spacing: ElsewhereTheme.Spacing.lg) {
                Image("elsewhere-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())

                VStack(spacing: ElsewhereTheme.Spacing.sm) {
                    Text("Elsewhere")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(ElsewhereTheme.Color.sand)

                    Text("Find the extraordinary.")
                        .font(.system(size: 14, weight: .light, design: .serif).italic())
                        .foregroundStyle(ElsewhereTheme.Color.sunset)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            onDismiss()
        }
    }
}
