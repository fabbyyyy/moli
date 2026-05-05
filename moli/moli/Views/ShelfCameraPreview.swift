import AVFoundation
import SwiftUI
import UIKit

struct ShelfCameraPreview: UIViewControllerRepresentable {
    @Binding var captureTrigger: Int
    let onPhotoCaptured: (String?) -> Void
    let onCameraUnavailable: () -> Void

    func makeUIViewController(context: Context) -> ShelfCameraPreviewController {
        let controller = ShelfCameraPreviewController()
        context.coordinator.onPhotoCaptured = onPhotoCaptured
        context.coordinator.onCameraUnavailable = onCameraUnavailable
        controller.onPhotoCaptured = context.coordinator.notifyPhotoCaptured
        controller.onCameraUnavailable = context.coordinator.notifyCameraUnavailable
        return controller
    }

    func updateUIViewController(_ uiViewController: ShelfCameraPreviewController, context: Context) {
        context.coordinator.onPhotoCaptured = onPhotoCaptured
        context.coordinator.onCameraUnavailable = onCameraUnavailable
        
        guard captureTrigger != context.coordinator.lastCaptureTrigger else {
            return
        }

        context.coordinator.lastCaptureTrigger = captureTrigger
        uiViewController.capturePhoto()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastCaptureTrigger = 0
        var onPhotoCaptured: ((String?) -> Void)?
        var onCameraUnavailable: (() -> Void)?
        
        func notifyPhotoCaptured(_ imagePath: String?) {
            Task { @MainActor in
                self.onPhotoCaptured?(imagePath)
            }
        }
        
        func notifyCameraUnavailable() {
            Task { @MainActor in
                self.onCameraUnavailable?()
            }
        }
    }
}

final class ShelfCameraPreviewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onPhotoCaptured: ((String?) -> Void)?
    var onCameraUnavailable: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "moli.shelf.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "2A241D")
        checkCameraAccess()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    func capturePhoto() {
        guard isConfigured else {
            onCameraUnavailable?()
            return
        }

        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    if isGranted {
                        self?.configureSession()
                    } else {
                        self?.onCameraUnavailable?()
                    }
                }
            }
        case .denied, .restricted:
            onCameraUnavailable?()
        @unknown default:
            onCameraUnavailable?()
        }
    }

    private func configureSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            onCameraUnavailable?()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            session.beginConfiguration()
            session.sessionPreset = .photo

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
            isConfigured = true

            sessionQueue.async { [weak self] in
                self?.session.startRunning()
            }
        } catch {
            print("Error configuring shelf camera: \(error)")
            onCameraUnavailable?()
        }
    }

    private func stopSession() {
        guard isConfigured else {
            return
        }

        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.onPhotoCaptured?(nil)
            }
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("shelf-scan-\(UUID().uuidString)")
            .appendingPathExtension("jpg")

        do {
            try data.write(to: url, options: [.atomic])
            DispatchQueue.main.async {
                self.onPhotoCaptured?(url.path)
            }
        } catch {
            print("Error saving shelf scan image: \(error)")
            DispatchQueue.main.async {
                self.onPhotoCaptured?(nil)
            }
        }
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64

        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (42, 36, 29)
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
