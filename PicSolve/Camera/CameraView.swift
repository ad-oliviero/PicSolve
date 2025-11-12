//
//  CameraView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 12/11/25.
//

import AVFoundation
import AVKit
import PhotosUI
import SwiftUI

struct CameraView<T: Camera & Observable>: View {
    let camera: T
    @State var showPhotoPicker: Bool = false
    @StateObject var photoSelector: PhotoSelectorViewModel

    var body: some View {
        ZStack {
            PreviewContainer(camera: camera) {
                CameraPreview(source: camera.previewSource)
            }
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    HStack {
                        Button {
                            showPhotoPicker.toggle()
                        } label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .frame(width: 68, height: 68)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }.photosPicker(isPresented: $showPhotoPicker,
                                       selection: $photoSelector.selectedPhotos,
                                       maxSelectionCount: 1,
                                       selectionBehavior: .ordered,
                                       matching: .images)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        CaptureButton(camera: camera)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .frame(width: nil, height: 80)
                }
                .padding([.leading, .trailing])
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    CameraView(camera: PreviewCameraModel(), photoSelector: PhotoSelectorViewModel())
        .background(.black)
}
