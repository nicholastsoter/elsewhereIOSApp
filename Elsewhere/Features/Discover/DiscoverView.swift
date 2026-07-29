import SwiftUI
import MapKit

struct DiscoverView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedCategory: TravelCategory? = nil
    @State private var displayMode = DisplayMode.grid
    @State private var selectedDestinationID: UUID? = nil
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 10),
            span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 340)
        )
    )

    enum DisplayMode: Hashable { case grid, map }

    private var filtered: [Destination] {
        guard let cat = selectedCategory else { return appState.destinations }
        return appState.destinations.filter { $0.categories.contains(cat) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: ElsewhereTheme.Spacing.sm),
        GridItem(.flexible(), spacing: ElsewhereTheme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            categoryFilterRow
                .padding(.top, ElsewhereTheme.Spacing.sm)
                .background(ElsewhereTheme.Color.sand)

            switch displayMode {
            case .grid: gridContent
            case .map:  mapContent
            }
        }
        .background(ElsewhereTheme.Color.sand.ignoresSafeArea())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                displayModeToggle
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let destination = appState.destinations.first(where: { $0.id == id }) {
                DestinationDetailView(destination: destination)
            }
        }
        .onChange(of: displayMode) { _, _ in selectedDestinationID = nil }
        .onChange(of: selectedCategory) { _, _ in selectedDestinationID = nil }
    }

    // MARK: - Toggle

    private var displayModeToggle: some View {
        Picker("", selection: $displayMode) {
            Image(systemName: "square.grid.2x2").tag(DisplayMode.grid)
            Image(systemName: "map").tag(DisplayMode.map)
        }
        .pickerStyle(.segmented)
        .frame(width: 88)
    }

    // MARK: - Category filter

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ElsewhereTheme.Spacing.xs) {
                categoryChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(TravelCategory.allCases) { category in
                    categoryChip(label: category.label, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.vertical, ElsewhereTheme.Spacing.xs)
        }
    }

    private func categoryChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(ElsewhereTheme.Font.caption(13))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.dune)
                .foregroundStyle(isSelected ? Color.white : ElsewhereTheme.Color.ink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ElsewhereTheme.Spacing.sm) {
                ForEach(filtered) { destination in
                    NavigationLink(value: destination.id) {
                        DiscoverCard(destination: destination)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ElsewhereTheme.Spacing.md)
            .padding(.vertical, ElsewhereTheme.Spacing.md)
            .padding(.bottom, ElsewhereTheme.Spacing.xl)
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(filtered) { destination in
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: destination.latitude,
                            longitude: destination.longitude
                        )
                    ) {
                        destinationPin(for: destination)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.hybrid)
            .ignoresSafeArea(edges: .bottom)
            // Background tap clears the selection; annotation button taps consume
            // the touch before it reaches the map's gesture recognizer.
            .onTapGesture {
                withAnimation(.spring(duration: 0.25)) {
                    selectedDestinationID = nil
                }
            }

            if let id = selectedDestinationID,
               let destination = filtered.first(where: { $0.id == id }) {
                MapPreviewCard(destination: destination)
                    .padding(.horizontal, ElsewhereTheme.Spacing.md)
                    .padding(.bottom, ElsewhereTheme.Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedDestinationID)
    }

    private func destinationPin(for destination: Destination) -> some View {
        let isSelected = selectedDestinationID == destination.id
        return Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedDestinationID = destination.id
            }
        } label: {
            ZStack {
                // White ring ensures readability over any satellite background color
                Circle()
                    .fill(Color.white)
                    .frame(width: isSelected ? 46 : 37, height: isSelected ? 46 : 37)
                    .shadow(color: .black.opacity(isSelected ? 0.5 : 0.35), radius: 6, y: 3)
                Circle()
                    .fill(isSelected ? ElsewhereTheme.Color.ink : ElsewhereTheme.Color.sunset)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                Image(systemName: "mappin")
                    .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .animation(.spring(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map preview card

private struct MapPreviewCard: View {
    let destination: Destination

    var body: some View {
        NavigationLink(value: destination.id) {
            HStack(spacing: ElsewhereTheme.Spacing.sm) {
                AsyncImage(url: destination.heroImage?.thumbnailURL ?? destination.heroImage?.url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure:           ElsewhereTheme.Color.dune
                    default:                 SkeletonView(cornerRadius: ElsewhereTheme.Radius.small)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))

                VStack(alignment: .leading, spacing: ElsewhereTheme.Spacing.xs) {
                    Text(destination.name)
                        .font(ElsewhereTheme.Font.title(15))
                        .foregroundStyle(ElsewhereTheme.Color.ink)
                        .lineLimit(2)
                    Text(destination.country)
                        .font(ElsewhereTheme.Font.caption(13))
                        .foregroundStyle(ElsewhereTheme.Color.subtleText)
                    HStack(spacing: 3) {
                        Text("See more")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(ElsewhereTheme.Font.caption(13))
                    .foregroundStyle(ElsewhereTheme.Color.sunset)
                }

                Spacer()
            }
            .padding(ElsewhereTheme.Spacing.sm)
            .background(ElsewhereTheme.Color.sand)
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.card))
            .shadow(color: ElsewhereTheme.Color.ink.opacity(0.22), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid card

private struct DiscoverCard: View {
    let destination: Destination

    var body: some View {
        // Color gives the card a concrete, bounded size that .overlay clips to.
        // This prevents scaledToFill images from overflowing the card boundary.
        ElsewhereTheme.Color.dune
            .aspectRatio(2/3, contentMode: .fit)
            .overlay {
                AsyncImage(url: destination.heroImage?.thumbnailURL ?? destination.heroImage?.url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure:            Color.clear
                    default:                  SkeletonView()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, ElsewhereTheme.Color.ink.opacity(0.75)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(destination.name)
                            .font(ElsewhereTheme.Font.title(14))
                            .foregroundStyle(Color.white)
                        Text(destination.country)
                            .font(ElsewhereTheme.Font.caption(12))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ElsewhereTheme.Spacing.sm)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: ElsewhereTheme.Radius.small))
    }
}

#Preview {
    NavigationStack {
        DiscoverView().environmentObject(AppState())
    }
}
