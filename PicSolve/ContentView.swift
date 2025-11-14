//
//  ContentView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 07/11/25.
//

import Combine
import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject var photoSelector: PhotoSelectorViewModel = .init()
    @State private var camera = CameraModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        NavigationStack {
            TabView {
                Tab("Camera", systemImage: "camera") {
                    NavigationStack {
                        CameraView(camera: camera, photoSelector: photoSelector)
                            .task {
                                await camera.start()
                            }
                    }
                }
                Tab("Manual", systemImage: "keyboard.fill") {
                    VStack {
                        if photoSelector.image != nil {
                            Image(uiImage: photoSelector.image!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300)
                        }
                        ScrollView(.vertical) {
                            VStack {
                                ForEach(photoSelector.croppedImages.indices, id: \.self) { index in
                                    Image(uiImage: photoSelector.croppedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 300)
                                        .border(Color.blue, width: 2)
                                }
                            }
                        }
                        NavigationLink("Solve", destination: SolveView(photoSelector: photoSelector))
                            .buttonStyle(.glassProminent)
                        Spacer()
                    }
                    .onChange(of: photoSelector.selectedPhotos) { _, _ in
                        photoSelector.convertDataToImage()
                    }
                }
                Tab("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {}
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
