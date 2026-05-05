import MapKit
import SwiftUI
import UIKit

private enum MapFloatingControl {
    case location
    case route
}

struct RouteMapView: View {
    @State private var viewModel = RouteViewModel()
    @State private var locationService = RouteLocationService()
    @State private var activeMapControl: MapFloatingControl?
    @State private var isProgrammaticCameraMove = false
    @State private var scanStore: Store?
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
                navigationUserCoordinate: nil,
                navigationDestinationCoordinate: nil,
                showsNativeUserAnnotation: true,
                cameraChangedAction: clearActiveMapControlAfterUserMove
            )

            VStack {
                RouteProgressBar(
                    completedCount: viewModel.completedStopsCount,
                    totalCount: viewModel.routeStops.count,
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
        .task {
            await loadRoute()
        }
        .sheet(isPresented: selectedStopSheetBinding) {
            RouteSelectedStopSheet(
                selectedStop: viewModel.selectedStop,
                isNavigationActive: viewModel.isNavigationActive,
                routeErrorMessage: viewModel.routeErrorMessage,
                startNavigationAction: startNavigation,
                openMapsAction: openSelectedStopInMaps,
                scanAction: scanSelectedStopShelf
            )
            .presentationDetents([.height(320), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(320)))
        }
        .navigationDestination(item: $scanStore) { store in
            ShelfScanCameraView(store: store)
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
        LocalPersistenceService.shared.finalizeWeeklyOrderCart()
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
    
    private func scanSelectedStopShelf() {
        guard let store = viewModel.selectedStop?.store else {
            return
        }
        
        viewModel.selectSpot(id: nil)
        
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            scanStore = store
        }
    }
}

private struct RouteMap: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedSpotID: UUID?
    let spots: [RouteSpot]
    let routeSegments: [MKRoute]
    let navigationUserCoordinate: CLLocationCoordinate2D?
    let navigationDestinationCoordinate: CLLocationCoordinate2D?
    let showsNativeUserAnnotation: Bool
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

            if showsNativeUserAnnotation {
                UserAnnotation()
            }

            if let navigationDestinationCoordinate {
                Annotation("", coordinate: navigationDestinationCoordinate) {
                    NavigationDestinationMarker()
                }
            }

            if let navigationUserCoordinate {
                Annotation("", coordinate: navigationUserCoordinate) {
                    NavigationLocationPuck()
                }
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

private struct NavigationLocationPuck: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primaryBlue.opacity(0.18))
                .frame(width: 74, height: 74)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.75), lineWidth: 2)
                )

            Circle()
                .fill(AppTheme.Colors.primaryBlue)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
    }
}

private struct NavigationDestinationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.2), radius: 7, x: 0, y: 4)

            Image(systemName: "building.2.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

private struct RouteProgressBar: View {
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
    let scanAction: () -> Void

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
                    openMapsAction: openMapsAction,
                    scanAction: scanAction
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
    @State private var routeSheetDetent: PresentationDetent = .height(132)
    @State private var isVoiceGuidanceEnabled = true
    @State private var isVoiceControlsPresented = false
    @State private var selectedVoiceVolume: RouteVoiceVolume = .normal
    @State private var showsRecenterButton = false
    @State private var isProgrammaticNavigationCameraMove = false
    @State private var voiceGuidance = RouteVoiceGuidanceService()

    var body: some View {
        ZStack(alignment: .top) {
            RouteMap(
                cameraPosition: $cameraPosition,
                selectedSpotID: .constant(nil),
                spots: viewModel.routeSpots,
                routeSegments: viewModel.routeSegments,
                navigationUserCoordinate: locationService.currentLocation ?? viewModel.navigationRoute?.polyline.firstRouteCoordinate,
                navigationDestinationCoordinate: activeDestinationCoordinate,
                showsNativeUserAnnotation: false,
                cameraChangedAction: handleNavigationCameraChanged
            )

            RouteNavigationInstructionBanner(
                currentStep: viewModel.currentNavigationStep,
                nextStep: viewModel.nextNavigationStep
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack {
                Spacer(minLength: 270)
                ActiveNavigationFloatingControls(
                    isVoiceGuidanceEnabled: isVoiceGuidanceEnabled,
                    routeOverviewAction: centerOnNavigationRoute,
                    voiceAction: showVoiceControls
                )
                .padding(.trailing, 16)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            if showsRecenterButton && !isVoiceControlsPresented {
                ActiveNavigationRecenterButton(action: centerOnCurrentNavigationLocation)
                    .padding(.leading, 24)
                    .padding(.bottom, recenterButtonBottomPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: routeSheetDetent)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showsRecenterButton)
            }
        }
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
            navigationSheetContent
            .presentationDetents(
                isVoiceControlsPresented ? [.height(430)] : [.height(132), .height(318)],
                selection: $routeSheetDetent
            )
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
            .presentationCornerRadius(34)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(132)))
            .interactiveDismissDisabled()
        }
        .onDisappear {
            voiceGuidance.stop()
        }
    }

    @ViewBuilder
    private var navigationSheetContent: some View {
        if isVoiceControlsPresented {
            RouteVoiceControlsSheet(
                isVoiceGuidanceEnabled: $isVoiceGuidanceEnabled,
                selectedVolume: $selectedVoiceVolume,
                closeAction: closeVoiceControls
            )
        } else {
            RouteNavigationEndSheet(
                stop: viewModel.activeNavigationStop,
                arrivalTimeText: viewModel.navigationArrivalTimeText,
                travelTimeText: viewModel.navigationTravelTimeText,
                distanceText: viewModel.navigationRemainingDistanceText,
                distanceUnitText: viewModel.navigationRemainingDistanceUnit,
                isExpanded: routeSheetDetent != .height(132),
                callStoreAction: callActiveStore,
                stopNavigationAction: endNavigation
            )
        }
    }

    private var activeDestinationCoordinate: CLLocationCoordinate2D? {
        guard let store = viewModel.activeNavigationStop?.store else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
    }

    private var recenterButtonBottomPadding: CGFloat {
        routeSheetDetent == .height(132) ? 154 : 340
    }

    private func prepareNavigation() async {
        locationService.startFollowing()

        guard let currentLocation = locationService.currentLocation else {
            if isVoiceGuidanceEnabled, let stop = viewModel.activeNavigationStop {
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
        if shouldAnnounceStart || !showsRecenterButton {
            setNavigationCamera(on: currentLocation)
        }

        await viewModel.calculateNavigationRoute(startCoordinate: currentLocation)

        if isVoiceGuidanceEnabled, shouldAnnounceStart, let stop = viewModel.activeNavigationStop {
            voiceGuidance.setVolume(selectedVoiceVolume)
            voiceGuidance.start(route: viewModel.navigationRoute, destinationName: stop.store.name)
        }

        if isVoiceGuidanceEnabled {
            voiceGuidance.setVolume(selectedVoiceVolume)
            voiceGuidance.update(currentLocation: currentLocation, route: viewModel.navigationRoute)
        }
    }

    private func centerOnNavigationRoute() {
        guard let route = viewModel.navigationRoute else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(.fitting(route.polyline.boundingMapRect))
        }

        showsRecenterButton = true
    }

    private func centerOnCurrentNavigationLocation() {
        guard let currentLocation = locationService.currentLocation else {
            cameraPosition = .userLocation(followsHeading: true, fallback: .region(viewModel.mapRegion))
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            setNavigationCamera(on: currentLocation)
        }

        showsRecenterButton = false
    }

    private func showVoiceControls() {
        routeSheetDetent = .height(430)
        isVoiceControlsPresented = true
    }

    private func closeVoiceControls() {
        voiceGuidance.setVolume(selectedVoiceVolume)
        if !isVoiceGuidanceEnabled {
            voiceGuidance.stop()
        } else if let stop = viewModel.activeNavigationStop {
            voiceGuidance.start(route: viewModel.navigationRoute, destinationName: stop.store.name)
        }

        isVoiceControlsPresented = false
        routeSheetDetent = .height(132)
    }

    private func setNavigationCamera(on coordinate: CLLocationCoordinate2D) {
        isProgrammaticNavigationCameraMove = true
        cameraPosition = .camera(.navigationCamera(on: coordinate))

        Task {
            try? await Task.sleep(for: .milliseconds(650))
            isProgrammaticNavigationCameraMove = false
        }
    }

    private func handleNavigationCameraChanged() {
        guard !isProgrammaticNavigationCameraMove else {
            return
        }

        showsRecenterButton = true
    }

    private func callActiveStore() {
        guard let phoneURL = URL(string: "tel://5550101234"),
              UIApplication.shared.canOpenURL(phoneURL) else {
            return
        }

        UIApplication.shared.open(phoneURL)
    }

    private func endNavigation() {
        voiceGuidance.stop()
        stopNavigationAction()
    }
}

private struct RouteNavigationInstructionBanner: View {
    let currentStep: RouteNavigationStepInfo
    let nextStep: RouteNavigationStepInfo?

    var body: some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.tint(Color.black.opacity(0.56)), in: .rect(cornerRadius: 34))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34))
                .background(Color.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 34))
                .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Image(systemName: currentStep.systemImage)
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 84, height: 96)

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStep.distanceText)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.75)

                    Text(currentStep.instruction)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 16)

            if let nextStep {
                HStack(spacing: 18) {
                    Image(systemName: nextStep.systemImage)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white.opacity(0.74))
                        .frame(width: 84)

                    Text(nextStep.instruction)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.12))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ActiveNavigationFloatingControls: View {
    let isVoiceGuidanceEnabled: Bool
    let routeOverviewAction: () -> Void
    let voiceAction: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 16) {
                buttons
            }
        } else {
            buttons
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            ActiveNavigationFloatingButton(systemImage: "point.topleft.down.curvedto.point.bottomright.up", action: routeOverviewAction)
            ActiveNavigationFloatingButton(
                systemImage: isVoiceGuidanceEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill",
                action: voiceAction
            )
        }
    }
}

private struct ActiveNavigationRecenterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "location.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .frame(width: 68, height: 68)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .activeNavigationButtonSurface()
    }
}

private struct ActiveNavigationFloatingButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 66, height: 66)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .activeNavigationButtonSurface()
    }
}

private struct RouteVoiceControlsSheet: View {
    @Binding var isVoiceGuidanceEnabled: Bool
    @Binding var selectedVolume: RouteVoiceVolume
    let closeAction: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .glassEffect(.regular, in: .rect(cornerRadius: 34))
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Voice Controls")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.Colors.cardWhite.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VoiceMutePicker(isVoiceGuidanceEnabled: $isVoiceGuidanceEnabled)

            VStack(alignment: .leading, spacing: 10) {
                Text("Volume")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                VStack(spacing: 0) {
                    ForEach(RouteVoiceVolume.allCases) { volume in
                        Button {
                            selectedVolume = volume
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: volume == selectedVolume ? "waveform.circle.fill" : "waveform.circle")
                                    .font(.title2)
                                    .foregroundColor(volume == selectedVolume ? .blue : AppTheme.Colors.mutedGray)

                                Text(volume.title)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.textPrimary)

                                Spacer()

                                if volume == selectedVolume {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                        }
                        .buttonStyle(.plain)

                        if volume != RouteVoiceVolume.allCases.last {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(AppTheme.Colors.cardWhite.opacity(0.52), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 26)
    }
}

private struct VoiceMutePicker: View {
    @Binding var isVoiceGuidanceEnabled: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button {
                isVoiceGuidanceEnabled = false
            } label: {
                VoiceMuteOption(
                    systemImage: "speaker.slash.fill",
                    title: "Muted",
                    isSelected: !isVoiceGuidanceEnabled
                )
            }
            .buttonStyle(.plain)

            Button {
                isVoiceGuidanceEnabled = true
            } label: {
                VoiceMuteOption(
                    systemImage: "speaker.wave.3.fill",
                    title: "Unmuted",
                    isSelected: isVoiceGuidanceEnabled
                )
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(AppTheme.Colors.cardWhite.opacity(0.45), in: Capsule())
    }
}

private struct VoiceMuteOption: View {
    let systemImage: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.mutedGray)
                .frame(height: 52)

            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                Capsule()
                    .fill(AppTheme.Colors.cardWhite.opacity(0.82))
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func activeNavigationButtonSurface() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else {
            self.background(.regularMaterial, in: Circle())
                .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
        }
    }
}

private struct RouteNavigationEndSheet: View {
    let stop: RouteStop?
    let arrivalTimeText: String
    let travelTimeText: String
    let distanceText: String
    let distanceUnitText: String
    let isExpanded: Bool
    let callStoreAction: () -> Void
    let stopNavigationAction: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .glassEffect(.regular, in: .rect(cornerRadius: 34))
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
            NavigationSummaryMetrics(
                arrivalTimeText: arrivalTimeText,
                travelTimeText: travelTimeText,
                distanceText: distanceText,
                distanceUnitText: distanceUnitText
            )

            if isExpanded {
                VStack(spacing: 16) {
                    if let stop {
                        DestinationCallRow(store: stop.store, callStoreAction: callStoreAction)
                    }

                    Button(action: stopNavigationAction) {
                        Text("Terminar ruta")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(AppTheme.Colors.bimboRed)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, isExpanded ? 18 : 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }
}

private struct NavigationSummaryMetrics: View {
    let arrivalTimeText: String
    let travelTimeText: String
    let distanceText: String
    let distanceUnitText: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            NavigationSummaryMetric(value: arrivalTimeText, label: "arrival")
            NavigationSummaryMetric(value: travelTimeText.replacingOccurrences(of: " min", with: ""), label: "min")
            NavigationSummaryMetric(value: distanceText, label: distanceUnitText)
        }
    }
}

private struct NavigationSummaryMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DestinationCallRow: View {
    let store: Store
    let callStoreAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.brown.opacity(0.82))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(store.address)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: callStoreAction) {
                Image(systemName: "phone.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 52, height: 52)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.Colors.cardWhite.opacity(0.62), in: Capsule())
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
    let scanAction: () -> Void

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

                Button(action: scanAction) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Escanear")
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
    static func fitting(_ mapRect: MKMapRect) -> MKCoordinateRegion {
        let paddedRect = mapRect.insetBy(dx: -mapRect.width * 0.28, dy: -mapRect.height * 0.28)
        return MKCoordinateRegion(paddedRect)
    }

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

private extension MapCamera {
    static func navigationCamera(on coordinate: CLLocationCoordinate2D) -> MapCamera {
        MapCamera(
            centerCoordinate: coordinate,
            distance: 650,
            heading: 0,
            pitch: 58
        )
    }
}

private extension MKPolyline {
    var firstRouteCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else {
            return nil
        }

        return points()[0].coordinate
    }
}

#Preview {
    RouteMapView()
}
