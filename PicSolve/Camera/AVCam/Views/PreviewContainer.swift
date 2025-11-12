/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that provides a container view around the camera preview.
 */

import SwiftUI

// Portrait-orientation aspect ratios.
typealias AspectRatio = CGSize
let photoAspectRatio = AspectRatio(width: 3.0, height: 4.0)

/// A view that provides a container view around the camera preview.
///
/// This view applies transition effects when changing capture modes or switching devices.
/// On a compact device size, the app also uses this view to offset the vertical position
/// of the camera preview to better fit the UI when in photo capture mode.
@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var camera: CameraModel
    
    // When running in photo capture mode on a compact device size, move the preview area
    // update by the offset amount so that it's better centered between the top and bottom bars.
    private let photoModeOffset = CGFloat(-44)
    private let content: Content
    
    init(camera: CameraModel, @ViewBuilder content: () -> Content) {
        self.camera = camera
        self.content = content()
    }
    
    var body: some View {
        // On compact devices, show a view finder rectangle around the video preview bounds.
        if horizontalSizeClass == .compact {
            ZStack {
                content
            }
            .clipped()
            // Apply an appropriate aspect ratio based on the selected capture mode.
            .aspectRatio(aspectRatio, contentMode: .fit)
            // In photo mode, adjust the vertical offset of the preview area to better fit the UI.
            .offset(y: camera.captureMode == .photo ? photoModeOffset : 0)
        } else {
            // On regular-sized UIs, show the content in full screen.
            content
        }
    }
    
    var aspectRatio: AspectRatio {
        camera.captureMode == .photo ? photoAspectRatio : photoAspectRatio
    }
}
