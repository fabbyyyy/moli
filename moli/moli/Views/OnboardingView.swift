import SwiftUI
import AVFoundation
import CoreLocation

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var locationManager = LocationManagerDelegate()
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage(onNext: {
                withAnimation { currentPage = 1 }
            })
            .tag(0)
            
            CameraPermissionPage(onPermissionGranted: {
                withAnimation { currentPage = 2 }
            })
            .tag(1)
            
            LocationPermissionPage(locationManager: locationManager, onPermissionGranted: {
                withAnimation { hasSeenOnboarding = true }
            })
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(AppTheme.Colors.backgroundGray.ignoresSafeArea())
        // Prevent manual swiping so they MUST press buttons
        .simultaneousGesture(DragGesture())
    }
}

private struct WelcomePage: View {
    let onNext: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppTheme.Colors.primaryBlue.opacity(0.1)
                Image(systemName: "box.truck.badge.clock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.top)
            
            VStack(alignment: .leading, spacing: 24) {
                Text("¡Bienvenido a Moli!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Para que Moli pueda ser tu copiloto ideal y registrar tus visitas, necesitamos algunos permisos clave.")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: onNext) {
                    Text("Siguiente")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.primaryBlue)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 20)
            }
            .padding(24)
        }
    }
}

private struct CameraPermissionPage: View {
    let onPermissionGranted: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var isDenied = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppTheme.Colors.primaryBlue.opacity(0.1)
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.top)
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Permiso de Cámara")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Requerimos la cámara para poder escanear anaqueles y tomar fotos de evidencia durante tus entregas.")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if isDenied {
                    Button(action: openSettings) {
                        Text("Ir a Ajustes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                } else {
                    Button(action: requestCamera) {
                        Text("Dar Permiso")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.primaryBlue)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(24)
        }
        .onChange(of: scenePhase) { old, new in
            if new == .active {
                checkCameraStatus()
            }
        }
        .onAppear {
            checkCameraStatus()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func checkCameraStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            onPermissionGranted()
        } else if status == .denied || status == .restricted {
            isDenied = true
        }
    }
    
    private func requestCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        onPermissionGranted()
                    } else {
                        isDenied = true
                    }
                }
            }
        } else {
            checkCameraStatus()
        }
    }
}

private struct LocationPermissionPage: View {
    let locationManager: LocationManagerDelegate
    let onPermissionGranted: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var isDenied = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppTheme.Colors.primaryBlue.opacity(0.1)
                Image(systemName: "location.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.primaryBlue)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.top)
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Permiso de Ubicación")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Necesitamos la ubicación para guiarte en tu ruta diaria y registrar que visitaste cada tienda correctamente.")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if isDenied {
                    Button(action: openSettings) {
                        Text("Ir a Ajustes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                } else {
                    Button(action: requestLocation) {
                        Text("Dar Permiso")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.primaryBlue)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(24)
        }
        .onChange(of: scenePhase) { old, new in
            if new == .active {
                checkLocationStatus()
            }
        }
        .onAppear {
            checkLocationStatus()
            locationManager.onAuthChange = { status in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    onPermissionGranted()
                } else if status == .denied || status == .restricted {
                    isDenied = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func checkLocationStatus() {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            onPermissionGranted()
        } else if status == .denied || status == .restricted {
            isDenied = true
        }
    }
    
    private func requestLocation() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestLocationAccess()
        } else {
            checkLocationStatus()
        }
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }
    
    var onAuthChange: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthChange?(manager.authorizationStatus)
    }
}

#Preview {
    OnboardingView()
}
