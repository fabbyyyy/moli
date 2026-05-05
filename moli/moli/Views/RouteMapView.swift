import MapKit
import SwiftUI

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
            // Fondo del Mapa
            RouteMap(
                cameraPosition: $cameraPosition,
                selectedSpotID: $viewModel.selectedSpotID,
                spots: viewModel.routeSpots,
                routeSegments: viewModel.routeSegments,
                navigationUserCoordinate: nil,
                showsNativeUserAnnotation: true,
                cameraChangedAction: clearActiveMapControlAfterUserMove
            )

            // Barra de progreso superior
            VStack {
                RouteProgressBar(
                    completedCount: viewModel.completedStopsCount,
                    totalCount: viewModel.routeStops.count,
                    isCalculatingRoute: viewModel.isCalculatingRoute
                )
                .padding()

                Spacer()
            }

            // Controles flotantes (Centrar GPS / Ruta)
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
        
        .fullScreenCover(item: $scanStore) { store in
            NavigationStack {
                ShelfScanCameraView(store: store, nextStoreAction: completeScanFlowFromRouteMap)
            }
            .toolbar(.hidden, for: .tabBar)
        }
        
        // Pantalla completa para navegación paso a paso
        .fullScreenCover(isPresented: navigationScreenBinding) {
            RouteActiveNavigationView(
                viewModel: viewModel,
                locationService: locationService,
                stopNavigationAction: stopNavigation
            )
            .interactiveDismissDisabled()
        }
        
        // Hoja de detalles de la tienda seleccionada
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
        .task {
            await loadRoute()
        }
        .onChange(of: viewModel.selectedSpotID) { _, newValue in
            viewModel.selectSpot(id: newValue)
            centerOnSelectedSpot(id: newValue)
        }
    }

    // MARK: - Bindings de Navegación

    private var selectedStopSheetBinding: Binding<Bool> {
        Binding {
            viewModel.selectedStop != nil
        } set: { isPresented in
            if !isPresented { viewModel.selectSpot(id: nil) }
        }
    }

    private var navigationScreenBinding: Binding<Bool> {
        Binding {
            viewModel.isNavigationActive
        } set: { isPresented in
            if !isPresented { stopNavigation() }
        }
    }

    // MARK: - Acciones de Cámara y Ruta

    private func loadRoute() async {
        viewModel.loadRoute()
        cameraPosition = .region(viewModel.mapRegion)
        locationService.requestLocation()
        Task.detached(priority: .utility) { @MainActor in
            await viewModel.calculateRouteFromCurrentOrder()
        }
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
        guard let id, let spot = viewModel.routeSpots.first(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(.focusedRegion(on: spot.coordinate))
        }
    }

    // MARK: - Lógica de Navegación y Check-in

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
        guard let store = viewModel.selectedStop?.store else { return }

        viewModel.selectSpot(id: nil)

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            scanStore = store
        }
    }

    private func completeScanFlowFromRouteMap() {
        scanStore = nil
        viewModel.loadRoute()

        Task {
            await viewModel.calculateRouteFromCurrentOrder()
            cameraPosition = .region(viewModel.mapRegion)
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
        guard !isProgrammaticCameraMove else { return }
        activeMapControl = nil
    }
}
