import AVFoundation
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// AVFoundation preview layer with a native SwiftUI reticle overlay.
struct CardScannerView: UIViewRepresentable {
    var onPayload: @MainActor (String) -> Void
    var onUnavailable: @MainActor (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload, onUnavailable: onUnavailable)
    }

    func makeUIView(context: Context) -> PreviewHole {
        let hole = PreviewHole()
        hole.preview.videoGravity = .resizeAspectFill
        context.coordinator.attach(to: hole)
        return hole
    }

    func updateUIView(_ uiView: PreviewHole, context: Context) {
        uiView.preview.frame = uiView.bounds
        context.coordinator.preview = uiView.preview
    }

    static func dismantleUIView(_ uiView: PreviewHole, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class PreviewHole: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var preview: AVCaptureVideoPreviewLayer {
            // Programmer error: layerClass is AVCaptureVideoPreviewLayer.
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    /// Session is confined to `queue`. Metadata hops to the main actor.
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
        let onPayload: @MainActor (String) -> Void
        let onUnavailable: @MainActor (String) -> Void
        let session = AVCaptureSession()
        let queue = DispatchQueue(label: "sdl.card.capture")
        var preview: AVCaptureVideoPreviewLayer?
        var locked = false

        init(
            onPayload: @escaping @MainActor (String) -> Void,
            onUnavailable: @escaping @MainActor (String) -> Void
        ) {
            self.onPayload = onPayload
            self.onUnavailable = onUnavailable
        }

        @MainActor
        func attach(to hole: PreviewHole) {
            preview = hole.preview
            hole.preview.session = session
            queue.async { [self] in
                self.configure()
            }
        }

        func stop() {
            queue.async { [self] in
                if self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }

        private func configure() {
            session.beginConfiguration()
            session.sessionPreset = .high
            guard let device = AVCaptureDevice.default(for: .video) else {
                fail("This device has no camera to read a card code.")
                session.commitConfiguration()
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                fail("The camera could not start. Try again from Share.")
                session.commitConfiguration()
                return
            }
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: queue)
                if output.availableMetadataObjectTypes.contains(.qr) {
                    output.metadataObjectTypes = [.qr]
                }
            }
            session.commitConfiguration()
            if !session.isRunning {
                session.startRunning()
            }
        }

        private func fail(_ message: String) {
            Task { @MainActor in
                onUnavailable(message)
            }
        }

        nonisolated func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue,
                  !value.isEmpty
            else { return }
            Task { @MainActor in
                self.emit(value)
            }
        }

        @MainActor
        private func emit(_ value: String) {
            guard !locked else { return }
            locked = true
            onPayload(value)
            stop()
        }
    }
}

struct ScanReticle: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.62
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(Palette.accent, lineWidth: Radius.hairline * 2)
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}

enum CardQRRender {
    @MainActor
    static func image(for card: Card) -> UIImage? {
        guard let payload = try? CardQR.payload(for: card) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = payload
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext(options: nil)
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
