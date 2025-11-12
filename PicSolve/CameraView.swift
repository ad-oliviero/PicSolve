//
//  CameraView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 12/11/25.
//

import AVFoundation
import AVKit
import SwiftUI

@MainActor
struct CameraView<T: Camera & Observable>: PlatformView {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let camera: T

    var body: some View {
        ZStack {
            PreviewContainer(camera: camera) {
                CameraPreview(source: camera.previewSource)
//                    .onCameraCaptureEvent(defaultSoundDisabled: true) { event in
//                        if event.phase == .ended {
                ////                            let sound: AVCaptureEventSound
//                            switch camera.captureMode {
//                            case .photo:
                ////                                sound = .cameraShutter
//                                await camera.capturePhoto()
//                            }
//                        }
//                    }
//                    .onTapGesture { location in
//                        Task { await camera.focusAndExpose(at: location) }
//                    }
            }
            CameraUI(camera: camera)
        }
    }
}
