/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that displays an appropriate capture button for the selected capture mode.
 */

import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    @State var camera: CameraModel

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4.0)
                .fill(.white)
            Button {
                Task {
                    await camera.capturePhoto()
                }
            } label: {
                Circle()
                    .inset(by: 4.0 * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: 68)
    }

    private struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

#Preview("Photo") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .photo))
        .background(.black)
}
