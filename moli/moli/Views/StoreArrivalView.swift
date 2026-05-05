import SwiftUI
import AVFoundation

// Definimos el sintetizador fuera para que persista durante la sesión de la vista
private let storeArrivalSynth = AVSpeechSynthesizer()

struct StoreArrivalView: View {
    @Environment(\.dismiss) private var dismiss
    let store: Store

    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var manosLibres = false
    @State private var navigateToAnalysis = false

    var storeInfoText: String {
        "Llegaste a \(store.name). Última orden: \(store.lastOrderPieces) piezas hace \(store.lastVisitDaysAgo) días."
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Info tienda (Sección superior) ───────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                Text("PARADA #\(store.customerNumber.prefix(1)) · \(store.address)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.softBlue)
                    .foregroundColor(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.small)

                Text(store.name)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                HStack(spacing: 16) {
                    Circle()
                        .fill(AppTheme.Colors.softBlue)
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: "clock")
                                .foregroundColor(AppTheme.Colors.primaryBlue)
                                .font(.title3)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Última orden")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                        Text("\(store.lastOrderPieces) piezas hace \(store.lastVisitDaysAgo) días")
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                }
                .padding()
                .background(AppTheme.Colors.cardWhite)
                .cornerRadius(AppTheme.Radii.medium)
                .shadow(color: AppTheme.Shadows.card.color,
                        radius: AppTheme.Shadows.card.radius, x: 0, y: 4)

                // ── Manos libres ─────────────────────────────────────────
                HStack(spacing: 14) {
                    Toggle("", isOn: $manosLibres)
                        .labelsHidden()
                        .tint(AppTheme.Colors.primaryBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manos libres")
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(manosLibres ? "Leyendo info en voz alta…" : "Activa para guía por voz")
                            .font(.caption)
                            .foregroundColor(manosLibres ? AppTheme.Colors.primaryBlue : AppTheme.Colors.mutedGray)
                    }
                    Spacer()
                    Image(systemName: manosLibres ? "mic.fill" : "mic")
                        .foregroundColor(manosLibres ? AppTheme.Colors.primaryBlue : AppTheme.Colors.mutedGray)
                }
                .padding()
                .background(AppTheme.Colors.cardWhite)
                .cornerRadius(AppTheme.Radii.medium)
                .shadow(color: AppTheme.Shadows.card.color,
                        radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
                .onChange(of: manosLibres) { _, on in
                    if on {
                        storeArrivalSynth.stopSpeaking(at: .immediate)
                        let utt = AVSpeechUtterance(string: storeInfoText)
                        utt.voice = AVSpeechSynthesisVoice(language: "es-MX")
                        utt.rate  = 0.47
                        storeArrivalSynth.speak(utt)
                    } else {
                        storeArrivalSynth.stopSpeaking(at: .immediate)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .padding(.top, 10)

            // ── Zona de foto — Flexible ──────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                Text("FOTO DEL ANAQUEL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.horizontal)

                GeometryReader { geo in
                    ZStack {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.Radii.large, style: .continuous)
                                .fill(AppTheme.Colors.softBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radii.large, style: .continuous)
                                        .strokeBorder(
                                            AppTheme.Colors.primaryBlue.opacity(0.25),
                                            style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                                        )
                                )
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(AppTheme.Colors.primaryBlue)
                                    .clipShape(Circle())
                                Text("Toca para agregar foto")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.Colors.mutedGray)
                            }
                        }

                        Button { showCamera = true } label: {
                            Circle()
                                .fill(selectedImage != nil ? Color.black.opacity(0.5) : Color.clear)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedImage != nil ? .white : .clear)
                                )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.large, style: .continuous))
                    .onTapGesture { if selectedImage == nil { showCamera = true } }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // ── Botón Analizar ───────────────────────────────────────────
            if selectedImage != nil {
                Button(action: { navigateToAnalysis = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Analizar")
                            .fontWeight(.bold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(AppTheme.Colors.primaryBlue)
                    .cornerRadius(AppTheme.Radii.medium)
                    .shadow(color: AppTheme.Colors.primaryBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(AppTheme.Colors.backgroundGray.ignoresSafeArea())
        .navigationTitle("Llegaste a la tienda")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                }
                .tint(AppTheme.Colors.textPrimary)
            }
        }
        .navigationDestination(isPresented: $navigateToAnalysis) {
            AIAnalysisView(store: store, image: selectedImage)
        }
        .sheet(isPresented: $showCamera) {
            // Nombre actualizado para evitar conflictos
            StoreArrivalImagePicker(image: $selectedImage)
        }
        .animation(.default, value: selectedImage)
    }
}

// Estructura del Picker de Cámara con nombre único
struct StoreArrivalImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: StoreArrivalImagePicker
        init(_ parent: StoreArrivalImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        StoreArrivalView(store: MockStores.elPino)
    }
}



