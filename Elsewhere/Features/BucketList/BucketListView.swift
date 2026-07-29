import SwiftUI

struct BucketListView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.bucketList.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(SavedStatus.allCases) { status in
                        let items = appState.bucketList.filter { $0.saveStatus == status }
                        if !items.isEmpty {
                            Section(status.label.uppercased()) {
                                ForEach(items) { destination in
                                    row(destination)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Bucket List")
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
    }

    private func row(_ destination: Destination) -> some View {
        NavigationLink(value: destination.id) {
            HStack(spacing: ElsewhereTheme.Spacing.sm) {
                AsyncImage(url: destination.heroImage?.thumbnailURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        ElsewhereTheme.Color.dune
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))

                VStack(alignment: .leading) {
                    Text(destination.name).font(ElsewhereTheme.Font.title(16))
                    Text(destination.country).font(ElsewhereTheme.Font.caption()).foregroundStyle(ElsewhereTheme.Color.subtleText)
                }
                Spacer()
                if let score = destination.matchScore {
                    Text("\(score)%").font(ElsewhereTheme.Font.caption())
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ElsewhereTheme.Spacing.sm) {
            Image(systemName: "map").font(.system(size: 40)).foregroundStyle(ElsewhereTheme.Color.dune)
            Text("Nothing saved yet").font(ElsewhereTheme.Font.title(18))
            Text("Save destinations from Discover to start your list.")
                .font(ElsewhereTheme.Font.body(14))
                .foregroundStyle(ElsewhereTheme.Color.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NavigationStack { BucketListView().environmentObject(AppState()) }
}
