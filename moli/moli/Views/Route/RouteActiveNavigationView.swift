import MapKit
import SwiftUI
import UIKit

struct RouteActiveNavigationView: View {
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

// MARK: - Instruction Banner

struct RouteNavigationInstructionBanner: View {
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

// MARK: - Floating Controls

struct ActiveNavigationFloatingControls: View {
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

struct ActiveNavigationRecenterButton: View {
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

struct ActiveNavigationFloatingButton: View {
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

extension View {
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
