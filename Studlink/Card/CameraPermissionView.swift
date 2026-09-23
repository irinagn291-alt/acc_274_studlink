import AVFoundation
import SwiftUI

/// Pre-prompt before the system camera dialog. The proceed label is Continue.
struct CameraPermissionView: View {
    var onContinue: () -> Void

    private var type = TypeScale()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Spacer(minLength: Spacing.s2)
            Text("Scan a friend's card")
                .font(type.chainDisplay)
                .tracking(type.displayTracking)
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
            Text("The next step opens the system camera prompt so you can read a fixture code from another phone. Both phones then hold the same week, with no account.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: Spacing.s2)
            Button("Continue", action: onContinue)
                .buttonStyle(ChainButtonStyle())
                .accessibilityLabel("Continue")
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.background)
    }
}

struct CameraDeniedView: View {
    private var type = TypeScale()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Spacer(minLength: Spacing.s2)
            Text("Camera is off for Studlink")
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
            Text("Studlink cannot read a friend's card code until camera access is available. Open Settings if you want to scan.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: Spacing.s2)
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(ChainButtonStyle(kind: .quiet))
            .accessibilityLabel("Open Settings")
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.background)
    }
}

enum CameraGate {
    static func status() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func request() async -> AVAuthorizationStatus {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        return status()
    }
}
