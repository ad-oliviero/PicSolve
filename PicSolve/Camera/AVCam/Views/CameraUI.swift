/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that presents the main camera user interface.
 */

import AVFoundation
import SwiftUI

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: PlatformView {
    @State var camera: CameraModel

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Group {
            if isRegularSize {
                regularUI
            } else {
                compactUI
            }
        }
    }

    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        VStack(spacing: 0) {
            Spacer()
            MainToolbar(camera: camera)
                .padding(.bottom, 0)
        }
    }

    /// This view arranges UI elements in a layered stack.
    @ViewBuilder
    var regularUI: some View {
        VStack {
            Spacer()
            ZStack {
                MainToolbar(camera: camera)
            }
            .frame(width: 740)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(12)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    CameraUI(camera: PreviewCameraModel())
}
