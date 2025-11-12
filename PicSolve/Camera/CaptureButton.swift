//
//  CaptureButton.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 12/11/25.
//

import SwiftUI

@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    @State var camera: CameraModel
    var onCapture: (Data?) -> Void = { _ in }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4.0)
                .fill(.white)
            Button {
                Task {
                    if let imageData = await camera.capturePhoto() {
                        onCapture(imageData)
                    }
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

#Preview {
    CaptureButton(camera: PreviewCameraModel(captureMode: .photo))
        .background(.black)
}
