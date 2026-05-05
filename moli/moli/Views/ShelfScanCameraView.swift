import SwiftUI

struct ShelfScanCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let store: Store

    @State private var navigateToAnalysis = false
    @State private var capturedImagePath: String?
    @State private var cameraUnavailable = false
    @State private var captureTrigger = 0
    
    var body: some View {
        ZStack {
            Color(hex: "2A241D").ignoresSafeArea()
            
            if cameraUnavailable {
                ShelfMockView(showGuides: true)
                    .padding(.horizontal)
            } else {
                ShelfCameraPreview(
                    captureTrigger: $captureTrigger,
                    onPhotoCaptured: handleCapturedImage,
                    onCameraUnavailable: {
                        cameraUnavailable = true
                    }
                )
                .ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Button(action: dismissView) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    Text(cameraUnavailable ? "Simulador sin cámara" : "Alinea las repisas con las 3 líneas")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    // Balance placeholder
                    Image(systemName: "xmark").opacity(0).padding(10)
                }
                .padding()
                
                Spacer()
                
                if cameraUnavailable {
                    Text("Toca para continuar con captura demo")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: captureShelfImage) {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 70, height: 70)
                            Circle()
                                .fill(AppTheme.Colors.primaryBlue)
                                .frame(width: 58, height: 58)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            
            VStack {
                HStack {
                    CameraCornerGuide(rotation: 0)
                    Spacer()
                    CameraCornerGuide(rotation: 90)
                }
                Spacer()
                HStack {
                    CameraCornerGuide(rotation: 270)
                    Spacer()
                    CameraCornerGuide(rotation: 180)
                }
            }
            .padding()
            .allowsHitTesting(false)
        }
        .navigationDestination(isPresented: $navigateToAnalysis) {
            AIAnalysisView(store: store, imagePath: capturedImagePath)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func dismissView() {
        dismiss()
    }
    
    private func captureShelfImage() {
        guard !cameraUnavailable else {
            capturedImagePath = nil
            navigateToAnalysis = true
            return
        }
        
        captureTrigger += 1
    }
    
    private func handleCapturedImage(_ imagePath: String?) {
        capturedImagePath = imagePath
        navigateToAnalysis = true
    }
    
}

private struct CameraCornerGuide: View {
    let rotation: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(Color.white, lineWidth: 3)
        .frame(width: 30, height: 30)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    ShelfScanCameraView(store: MockStores.elPino)
}
