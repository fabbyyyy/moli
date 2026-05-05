import SwiftUI
import PhotosUI

struct StoreArrivalView: View {
    @Environment(\.dismiss) private var dismiss
    let store: Store

    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var galleryItem: PhotosPickerItem?
    @State private var manosLibres = false
    @State private var navigateToAnalysis = false

    var storeInfoText: String {
        "Llegaste a \(store.name). Última orden: \(store.lastOrderPieces) piezas hace \(store.lastVisitDaysAgo) días."
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Foto de la tienda ────────────────────────────────────────
            StoreHeaderImage(store: store)
                .frame(height: 180)

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

            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .padding(.top, 10)

            // ── Zona de fotos — múltiples anaqueles ──────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FOTOS DE ANAQUELES")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Spacer()
                    Text("\(selectedImages.count) foto\(selectedImages.count == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(AppTheme.Colors.primaryBlue)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Miniaturas de fotos capturadas
                        ForEach(selectedImages.indices, id: \.self) { i in
                            ShelfThumbnail(
                                image: selectedImages[i],
                                number: i + 1,
                                onDelete: { selectedImages.remove(at: i) }
                            )
                        }

                        // Botón agregar anaquel
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Button { showCamera = true } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(AppTheme.Colors.primaryBlue)
                                        .clipShape(Circle())
                                }
                                PhotosPicker(selection: $galleryItem, matching: .images) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.Colors.primaryBlue)
                                        .frame(width: 36, height: 36)
                                        .background(AppTheme.Colors.softBlue)
                                        .clipShape(Circle())
                                }
                            }
                            Text(selectedImages.isEmpty ? "Agregar foto" : "+ Anaquel")
                                .font(.caption2).bold()
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        }
                        .frame(width: 110, height: 110)
                        .background(AppTheme.Colors.softBlue.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.medium))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 10)

            // ── Manos libres ─────────────────────────────────────────────
            HStack(spacing: 14) {
                Toggle("", isOn: $manosLibres)
                    .labelsHidden()
                    .tint(AppTheme.Colors.primaryBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manos libres")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(manosLibres ? "Leerá el análisis en voz alta" : "Activa para guía por voz")
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
            .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // ── Botón Analizar ───────────────────────────────────────────
            if !selectedImages.isEmpty {
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
            AIAnalysisView(store: store, images: selectedImages, manosLibres: manosLibres)
        }
        .sheet(isPresented: $showCamera) {
            ShelfMultiImagePicker { img in selectedImages.append(img) }
        }
        .onChange(of: galleryItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImages.append(img)
                    galleryItem = nil
                }
            }
        }
        .animation(.default, value: selectedImages.count)
    }
}

struct ShelfMultiImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
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
        let parent: ShelfMultiImagePicker
        init(_ parent: ShelfMultiImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImagePicked(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

private struct StoreHeaderImage: View {
    let store: Store

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let name = store.imageName, let uiImg = UIImage(named: name) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .clipped()
            } else {
                // Placeholder: gradiente con inicial de la tienda
                LinearGradient(
                    colors: [AppTheme.Colors.primaryBlue.opacity(0.85), AppTheme.Colors.primaryBlue.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                HStack(spacing: 14) {
                    Text(String(store.name.prefix(1)))
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(.white.opacity(0.25))
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.15))
                }
            }

            // Degradado inferior para legibilidad
            LinearGradient(
                colors: [.clear, AppTheme.Colors.backgroundGray.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .clipped()
    }
}

private struct ShelfThumbnail: View {
    let image: UIImage
    let number: Int
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 110, height: 110).clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.medium))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3).foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(4)

            Text("Anaquel \(number)")
                .font(.caption2).bold().foregroundColor(.white)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: 110, height: 110)
    }
}

#Preview {
    NavigationStack {
        StoreArrivalView(store: MockStores.elPino)
    }
}



