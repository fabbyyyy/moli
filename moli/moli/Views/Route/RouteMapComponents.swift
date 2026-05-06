import MapKit
import SwiftUI

struct RouteMap: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedSpotID: UUID?
    let spots: [RouteSpot]
    let routeSegments: [MKRoute]
    let regionInsights: [RegionInsight]
    let navigationUserCoordinate: CLLocationCoordinate2D?
    let showsNativeUserAnnotation: Bool
    let cameraChangedAction: () -> Void
    let onRegionTapped: (RegionInsight) -> Void

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedSpotID) {
            ForEach(routeSegments, id: \.self) { route in
                MapPolyline(route.polyline)
                    .stroke(AppTheme.Colors.primaryBlue, lineWidth: 5)
            }

            ForEach(spots) { spot in
                Marker(
                    "#\(spot.stopNumber) \(spot.store.name)",
                    systemImage: spot.isCompleted ? "checkmark.circle.fill" : "storefront.fill",
                    coordinate: spot.coordinate
                )
                .tint(spot.isCurrent ? AppTheme.Colors.alertOrange : AppTheme.Colors.primaryBlue)
                .tag(spot.id)
            }

            if showsNativeUserAnnotation {
                UserAnnotation()
            }

            if let navigationUserCoordinate {
                Annotation("", coordinate: navigationUserCoordinate) {
                    NavigationLocationPuck()
                }
            }

            ForEach(regionInsights) { insight in
                Annotation("", coordinate: insight.coordinate) {
                    RegionInsightPin(region: insight, onTap: onRegionTapped)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .continuous) { _ in
            cameraChangedAction()
        }
        .ignoresSafeArea()
    }
}

struct NavigationLocationPuck: View {
    @State private var pulse: CGFloat = 1.0
    @State private var haloOpacity: Double = 0.4

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(pulse)
                .opacity(haloOpacity)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)

            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)

            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
        }
        .onAppear {
            pulse = 1.3
            haloOpacity = 0.05
        }
    }
}

struct RouteProgressBar: View {
    let completedCount: Int
    let totalCount: Int
    let isCalculatingRoute: Bool

    private var progress: CGFloat {
        guard totalCount > 0 else {
            return 0
        }

        return CGFloat(completedCount) / CGFloat(totalCount)
    }

    var body: some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radii.extraLarge))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radii.extraLarge))
                .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
        }
    }

    private var content: some View {
        HStack(spacing: 14) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primaryBlue)

            Text("\(completedCount) de \(totalCount) tiendas")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer(minLength: 20)

            if isCalculatingRoute {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(AppTheme.Colors.primaryBlue)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.softBlue)

                        Capsule()
                            .fill(AppTheme.Colors.primaryBlue)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(width: 86, height: 7)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }
}

enum MapFloatingControl {
    case location
    case route
}

struct MapFloatingControls: View {
    let locationAction: () -> Void
    let routeAction: () -> Void
    let insightsAction: () -> Void
    let activeControl: MapFloatingControl?
    let isRaised: Bool

    private let trailingPadding: CGFloat = 15
    private let pillWidth: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            controlPill
                .position(
                    x: geometry.size.width - trailingPadding - (pillWidth / 2),
                    y: geometry.size.height * (isRaised ? 0.45 : 0.65)
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isRaised)
        }
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private var controlPill: some View {
        if #available(iOS 26, *) {
            VStack(spacing: 20) {
                FloatingMapButton(
                    systemImage: "chart.bar",
                    filledSystemImage: "chart.bar.fill",
                    isActive: false,
                    action: insightsAction
                )
                FloatingMapButton(
                    systemImage: "location",
                    filledSystemImage: "location.fill",
                    isActive: activeControl == .location,
                    action: locationAction
                )
                FloatingMapButton(
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    filledSystemImage: "point.topleft.down.to.point.bottomright.curvepath.fill",
                    isActive: activeControl == .route,
                    action: routeAction
                )
            }
            .font(.title3)
            .foregroundStyle(AppTheme.Colors.primaryBlue)
            .padding(.vertical, 10)
            .padding(.horizontal, 5)
            .glassEffect(.regular, in: .capsule)
        } else {
            VStack(spacing: 10) {
                FloatingMapButton(
                    systemImage: "chart.bar",
                    filledSystemImage: "chart.bar.fill",
                    isActive: false,
                    action: insightsAction
                )
                FloatingMapButton(
                    systemImage: "location",
                    filledSystemImage: "location.fill",
                    isActive: activeControl == .location,
                    action: locationAction
                )
                FloatingMapButton(
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    filledSystemImage: nil,
                    isActive: activeControl == .route,
                    action: routeAction
                )
            }
            .font(.title3)
            .foregroundStyle(AppTheme.Colors.primaryBlue)
            .padding(.vertical, 10)
            .padding(.horizontal, 5)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
        }
    }
}

struct FloatingMapButton: View {
    let systemImage: String
    let filledSystemImage: String?
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? filledSystemImage ?? systemImage : systemImage)
                .fontWeight(isActive ? .bold : .regular)
                .frame(width: 34, height: 34)
                .background {
                    if isActive, filledSystemImage == nil {
                        Circle()
                            .fill(AppTheme.Colors.primaryBlue.opacity(0.12))
                            .frame(width: 28, height: 28)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Region Insight Components

struct RegionInsightPin: View {
    let region: RegionInsight
    let onTap: (RegionInsight) -> Void
    @State private var pulse = false

    var body: some View {
        Button {
            onTap(region)
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.alertOrange.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .fill(AppTheme.Colors.alertOrange)
                    .frame(width: 32, height: 32)
                    .shadow(color: AppTheme.Colors.alertOrange.opacity(0.4), radius: 6, y: 2)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}

struct RegionInsightSheet: View {
    let regions: [RegionInsight]
    @Binding var currentIndex: Int
    let onRegionChanged: (RegionInsight) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator dots
            HStack(spacing: 6) {
                ForEach(0..<regions.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? AppTheme.Colors.alertOrange : AppTheme.Colors.mutedGray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            TabView(selection: $currentIndex) {
                ForEach(Array(regions.enumerated()), id: \.element.id) { index, region in
                    RegionInsightPage(region: region)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { _, newValue in
                let clamped = max(0, min(newValue, regions.count - 1))
                onRegionChanged(regions[clamped])
            }
        }
    }
}

private struct RegionInsightPage: View {
    let region: RegionInsight

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.alertOrange.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "chart.bar.fill")
                            .font(.title3.weight(.bold))
                            .foregroundColor(AppTheme.Colors.alertOrange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(region.region)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Insights de la región")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }

                    Spacer()
                }

                Divider()

                // Top Products
                InsightSection(
                    icon: "star.fill",
                    iconColor: AppTheme.Colors.alertOrange,
                    title: "Productos con mayor rotación",
                    content: region.topProducts
                )

                // Reason
                InsightSection(
                    icon: "lightbulb.fill",
                    iconColor: AppTheme.Colors.primaryBlue,
                    title: "¿Por qué se venden más aquí?",
                    content: region.reason
                )
            }
            .padding(24)
        }
    }
}

private struct InsightSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            Text(content)
                .font(.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 2)
    }
}
