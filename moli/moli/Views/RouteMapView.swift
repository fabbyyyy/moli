import MapKit
import SwiftUI

private enum MapFloatingControl {
    case location
    case route
}

struct RouteMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RouteViewModel()
    @State private var locationService = RouteLocationService()
    @State private var activeMapControl: MapFloatingControl?
    @State private var isProgrammaticCameraMove = false
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    ))

    var body: some View {
        ZStack {
            RouteMap(
                cameraPosition: $cameraPosition,
                selectedSpotID: $viewModel.selectedSpotID,
                spots: viewModel.routeSpots,
                routeSegments: viewModel.routeSegments,
                cameraChangedAction: clearActiveMapControlAfterUserMove
            )

            VStack {
                RouteProgressBar(
                    completedCount: viewModel.completedStopsCount,
                    totalCount: viewModel.routeStops.count,
                    distanceText: viewModel.totalRouteDistanceText,
                    travelTimeText: viewModel.totalRouteTravelTimeText,
                    isCalculatingRoute: viewModel.isCalculatingRoute
                )
                .padding()

                Spacer()
            }

            MapFloatingControls(
                locationAction: centerOnCurrentLocation,
                routeAction: centerOnRoute,
                activeControl: activeMapControl,
                isRaised: viewModel.selectedStop != nil || viewModel.isNavigationActive
            )
        }
        .navigationTitle("Tu Ruta")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: dismissView) {
                    Image(systemName: "chevron.left")
                }
                .tint(AppTheme.Colors.textPrimary)
            }
        }
        .task {
            await loadRoute()
        }
        .sheet(isPresented: selectedStopSheetBinding) {
            RouteSelectedStopSheet(
                selectedStop: viewModel.selectedStop,
                isNavigationActive: viewModel.isNavigationActive,
                routeErrorMessage: viewModel.routeErrorMessage,
                startNavigationAction: startNavigation,
                openMapsAction: openSelectedStopInMaps
            )
            .presentationDetents([.height(320), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(320)))
        }
        .fullScreenCover(isPresented: navigationScreenBinding) {
            RouteActiveNavigationView(
                viewModel: viewModel,
                locationService: locationService,
                stopNavigationAction: stopNavigation
            )
            .interactiveDismissDisabled()
        }
        .onChange(of: viewModel.selectedSpotID) { _, newValue in
            viewModel.selectSpot(id: newValue)
            centerOnSelectedSpot(id: newValue)
        }
    }

    private var selectedStopSheetBinding: Binding<Bool> {
        Binding {
            viewModel.selectedStop != nil
        } set: { isPresented in
            if !isPresented {
                viewModel.selectSpot(id: nil)
            }
        }
    }

    private var navigationScreenBinding: Binding<Bool> {
        Binding {
            viewModel.isNavigationActive
        } set: { isPresented in
            if !isPresented {
                stopNavigation()
            }
        }
    }

    private func dismissView() {
        dismiss()
    }

    private func loadRoute() async {
        viewModel.loadRoute()
        cameraPosition = .region(viewModel.mapRegion)
        locationService.requestLocation()
        await viewModel.calculateRouteFromCurrentOrder()
    }

    private func centerOnCurrentLocation() {
        locationService.requestLocation()
        beginProgrammaticCameraMove(for: .location)

        if let currentLocation = locationService.currentLocation {
            cameraPosition = .region(.centeredRegion(on: currentLocation))
        } else {
            cameraPosition = .userLocation(followsHeading: false, fallback: .region(viewModel.mapRegion))
        }
    }

    private func centerOnRoute() {
        beginProgrammaticCameraMove(for: .route)

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(viewModel.mapRegion)
        }
    }

    private func centerOnSelectedSpot(id: UUID?) {
        guard let id, let spot = viewModel.routeSpots.first(where: { $0.id == id }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(.focusedRegion(on: spot.coordinate))
        }
    }

    private func beginProgrammaticCameraMove(for control: MapFloatingControl) {
        activeMapControl = control
        isProgrammaticCameraMove = true

        Task {
            try? await Task.sleep(for: .milliseconds(450))
            isProgrammaticCameraMove = false
        }
    }

    private func clearActiveMapControlAfterUserMove() {
        guard !isProgrammaticCameraMove else {
            return
        }

        activeMapControl = nil
    }

    private func startNavigation() {
        viewModel.startNavigation(to: viewModel.selectedStop)
        locationService.startFollowing()
    }

    private func stopNavigation() {
        viewModel.stopNavigation()
        locationService.stopFollowing()
        Task {
            await viewModel.calculateRouteFromCurrentOrder()
            cameraPosition = .region(viewModel.mapRegion)
        }
    }

    private func openSelectedStopInMaps() {
        viewModel.openSelectedStopInMaps()
    }
}

private struct RouteMap: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedSpotID: UUID?
    let spots: [RouteSpot]
    let routeSegments: [MKRoute]
    let cameraChangedAction: () -> Void

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

            UserAnnotation()
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

private struct RouteProgressBar: View {
    let completedCount: Int
    let totalCount: Int
    let distanceText: String
    let travelTimeText: String
    let isCalculatingRoute: Bool

    private var progress: CGFloat {
        guard totalCount > 0 else {
            return 0
        }

        return CGFloat(completedCount) / CGFloat(totalCount)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                Text("\(completedCount) de \(totalCount) tiendas")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.softBlue)

                        Capsule()
                            .fill(AppTheme.Colors.primaryBlue)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(width: 80, height: 6)
            }

            HStack(spacing: 10) {
                Label(distanceText, systemImage: "road.lanes")
                Text("·")
                Label(travelTimeText, systemImage: "clock")
                Spacer()
                if isCalculatingRoute {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .font(.caption)
            .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.extraLarge)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
    }
}

private struct MapFloatingControls: View {
    let locationAction: () -> Void
    let routeAction: () -> Void
    let activeControl: MapFloatingControl?
    let isRaised: Bool

    private let trailingPadding: CGFloat = 15
    private let pillWidth: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            controlPill
                .position(
                    x: geometry.size.width - trailingPadding - (pillWidth / 2),
                    y: geometry.size.height * (isRaised ? 0.50 : 0.74)
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

private struct FloatingMapButton: View {
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

private struct RouteSelectedStopSheet: View {
    let selectedStop: RouteStop?
    let isNavigationActive: Bool
    let routeErrorMessage: String?
    let startNavigationAction: () -> Void
    let openMapsAction: () -> Void

    var body: some View {
        if let selectedStop {
            VStack(alignment: .leading, spacing: 16) {
                RouteStopHeader(stop: selectedStop, isNavigationActive: isNavigationActive)
                RouteStopStoreInfo(store: selectedStop.store)
                RouteStopMetrics(store: selectedStop.store)

                if let routeErrorMessage {
                    Text(routeErrorMessage)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.alertOrange)
                }

                RouteNavigationActions(
                    store: selectedStop.store,
                    startNavigationAction: startNavigationAction,
                    openMapsAction: openMapsAction
                )
            }
            .padding(AppTheme.Radii.large)
        }
    }
}

private struct RouteActiveNavigationView: View {
    @Bindable var viewModel: RouteViewModel
    let locationService: RouteLocationService
    let stopNavigationAction: () -> Void

    @State private var cameraPosition: MapCameraPosition = .userLocation(
        followsHeading: true,
        fallback: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    )
    @State private var routeSheetDetent: PresentationDetent = .height(108)
    @State private var voiceGuidance = RouteVoiceGuidanceService()

    var body: some View {
        ZStack(alignment: .top) {
            RouteMap(
                cameraPosition: $cameraPosition,
                selectedSpotID: .constant(nil),
                spots: viewModel.routeSpots,
                routeSegments: viewModel.routeSegments,
                cameraChangedAction: {}
            )

            RouteNavigationInstructionBanner(
                instruction: viewModel.navigationInstructionText,
                stop: viewModel.activeNavigationStop
            )
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .statusBarHidden(true)
        .task {
            await prepareNavigation()
        }
        .onChange(of: locationService.currentLocationKey) { _, _ in
            guard let currentLocation = locationService.currentLocation else {
                return
            }

            Task {
                await updateNavigation(from: currentLocation)
            }
        }
        .sheet(isPresented: .constant(true)) {
            RouteNavigationEndSheet(
                stop: viewModel.activeNavigationStop,
                distanceText: viewModel.navigationDistanceText,
                travelTimeText: viewModel.navigationTravelTimeText,
                stopNavigationAction: endNavigation
            )
            .presentationDetents([.height(108), .height(250)], selection: $routeSheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(108)))
            .interactiveDismissDisabled()
        }
        .onDisappear {
            voiceGuidance.stop()
        }
    }

    private func prepareNavigation() async {
        locationService.startFollowing()

        guard let currentLocation = locationService.currentLocation else {
            if let stop = viewModel.activeNavigationStop {
                voiceGuidance.start(route: nil, destinationName: stop.store.name)
            }
            return
        }

        await updateNavigation(from: currentLocation, shouldAnnounceStart: true)
    }

    private func updateNavigation(
        from currentLocation: CLLocationCoordinate2D,
        shouldAnnounceStart: Bool = false
    ) async {
        cameraPosition = .userLocation(followsHeading: true, fallback: .region(.centeredRegion(on: currentLocation)))
        await viewModel.calculateNavigationRoute(startCoordinate: currentLocation)

        if shouldAnnounceStart, let stop = viewModel.activeNavigationStop {
            voiceGuidance.start(route: viewModel.navigationRoute, destinationName: stop.store.name)
        }

        voiceGuidance.update(currentLocation: currentLocation, route: viewModel.navigationRoute)
    }

    private func endNavigation() {
        voiceGuidance.stop()
        stopNavigationAction()
    }
}

private struct RouteNavigationInstructionBanner: View {
    let instruction: String
    let stop: RouteStop?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.up")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(AppTheme.Colors.primaryBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(instruction)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)

                if let stop {
                    Text("#\(stop.stopNumber) · \(stop.store.name)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(AppTheme.Colors.primaryBlue)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.extraLarge))
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
    }
}

private struct RouteNavigationEndSheet: View {
    let stop: RouteStop?
    let distanceText: String
    let travelTimeText: String
    let stopNavigationAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(travelTimeText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(distanceText)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }

                Spacer()

                if let stop {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Parada #\(stop.stopNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.primaryBlue)
                        Text(stop.store.name)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }
            }

            if let stop {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Destino")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Text(stop.store.address)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                }
            }

            Button(action: stopNavigationAction) {
                Text("TERMINAR RUTA")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radii.medium)
            }
        }
        .padding(AppTheme.Radii.large)
    }
}

private struct RouteStopHeader: View {
    let stop: RouteStop
    let isNavigationActive: Bool

    var body: some View {
        HStack {
            Text(isNavigationActive ? "NAVEGANDO · #\(stop.stopNumber)" : "TIENDA · #\(stop.stopNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.softBlue)
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .cornerRadius(AppTheme.Radii.small)

            Spacer()

            Text("Última visita hace \(stop.store.lastVisitDaysAgo) días")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

private struct RouteStopStoreInfo: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(store.address)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
}

private struct RouteStopMetrics: View {
    let store: Store

    var body: some View {
        HStack {
            RouteMetric(title: "DISTANCIA", value: "\(String(format: "%.1f", store.distanceKm)) km")

            Spacer()

            RouteMetric(title: "TIEMPO", value: "\(store.estimatedMinutes) min")

            Spacer()

            VStack(alignment: .trailing) {
                Text("ÚLTIMA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(store.lastOrderPieces)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("pzas")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
            }
        }
    }
}

private struct RouteMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.mutedGray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

private struct RouteNavigationActions: View {
    let store: Store
    let startNavigationAction: () -> Void
    let openMapsAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: startNavigationAction) {
                HStack {
                    Image(systemName: "location.north.line.fill")
                    Text("INICIAR NAVEGACIÓN")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.Radii.medium)
            }

            HStack(spacing: 10) {
                Button(action: openMapsAction) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Abrir en Mapas")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.softBlue)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                }

                NavigationLink(destination: StoreArrivalView(store: store)) {
                    HStack {
                        Image(systemName: "storefront.fill")
                        Text("Llegué")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.softBlue)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                }
            }
        }
    }
}

private extension MKCoordinateRegion {
    static func centeredRegion(on coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    static func focusedRegion(on coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    }
}

#Preview {
    RouteMapView()
}
