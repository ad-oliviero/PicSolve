/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that displays controls to capture, switch cameras, and view the last captured media item.
 */

import PhotosUI
import SwiftUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar<CameraModel: Camera>: PlatformView {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var camera: CameraModel

    var body: some View {
        HStack {
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(width: width, height: height)
        .padding([.leading, .trailing])
    }

    var width: CGFloat? { nil }
    var height: CGFloat? { 80 }
}

#Preview {
    Group {
        MainToolbar(camera: PreviewCameraModel())
    }
}
